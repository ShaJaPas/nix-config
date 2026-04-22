#!/usr/bin/env bash
# sing-box manager backend for DMS plugin

set -uo pipefail

SING_BOX_DIR="$HOME/.config/sing-box"
# Writable runtime dir (plugin dir in nix store is read-only)
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/singbox-manager"
PID_FILE="$RUNTIME_DIR/singbox.pid"
LOG_FILE="$RUNTIME_DIR/singbox.log"
TMP_CONFIG="$RUNTIME_DIR/active_config.json"
# Persistent data dir for app selections
DATA_DIR="$HOME/.local/share/singBoxManager"
APPS_DIR="$DATA_DIR/apps"

mkdir -p "$RUNTIME_DIR" "$APPS_DIR"

cmd="${1:-status}"
shift 2>/dev/null || true

# ─── helpers ──────────────────────────────────────────────────────────────────

resolve_proc_name() {
    # Follow nix wrapper script chains to find the real ELF binary name
    # sing-box matches process_name against /proc/pid/exe basename
    local exec_bin="$1"
    local exe_path
    exe_path=$(command -v "$exec_bin" 2>/dev/null) || { echo "$exec_bin"; return; }

    local depth=0
    while [[ $depth -lt 6 ]]; do
        [[ ! -f "$exe_path" ]] && { echo "$exec_bin"; return; }
        # Detect ELF by magic bytes (7f 45 4c 46)
        local magic
        magic=$(od -A n -t x1 -N 4 "$exe_path" 2>/dev/null | tr -d ' \n')
        if [[ "$magic" == "7f454c46" ]]; then
            local base dir wrapped
            base=$(basename "$exe_path")
            dir=$(dirname "$exe_path")
            # NixOS capability-wrapper pattern: Foo ELF exec()'s .Foo-wrapped
            # sing-box sees .Foo-wrapped as the process name (from /proc/pid/exe)
            wrapped="$dir/.${base}-wrapped"
            if [[ -f "$wrapped" ]]; then
                echo ".${base}-wrapped"
            else
                echo "$base"
            fi
            return
        fi
        # It's a script — extract the next `exec` call
        # Handles: exec "path" and exec -a "$0" "path"
        local next
        next=$(grep -m1 '^\s*exec ' "$exe_path" 2>/dev/null \
            | sed 's/^\s*exec\s*//' \
            | sed 's/-a\s*"[^"]*"\s*//' \
            | awk '{print $1}' \
            | tr -d '"'"'" \
            | sed 's/~\//$HOME\//')
        # Expand $HOME if needed
        next="${next/\$HOME/$HOME}"
        [[ -z "$next" ]] && { echo "$(basename "$exe_path")"; return; }
        if [[ "$next" == /* || "$next" == "$HOME"* ]]; then
            exe_path="$next"
        else
            exe_path=$(command -v "$next" 2>/dev/null) || { echo "$next"; return; }
        fi
        ((depth++))
    done
    echo "$(basename "$exe_path")"
}

resolve_icon() {
    local name="$1"
    [[ -z "$name" ]] && echo "" && return
    # Already an absolute path — use directly
    [[ "$name" == /* ]] && echo "$name" && return
    # Search preferred sizes in nix profile and system icon dirs
    for dir in \
        "$HOME/.nix-profile/share/icons/hicolor/scalable/apps" \
        "$HOME/.nix-profile/share/icons/hicolor/256x256/apps" \
        "$HOME/.nix-profile/share/icons/hicolor/512x512/apps" \
        "$HOME/.nix-profile/share/icons/hicolor/128x128/apps" \
        "$HOME/.nix-profile/share/icons/hicolor/48x48/apps" \
        "$HOME/.nix-profile/share/pixmaps" \
        "/run/current-system/sw/share/icons/hicolor/scalable/apps" \
        "/run/current-system/sw/share/icons/hicolor/256x256/apps" \
        "/run/current-system/sw/share/icons/hicolor/48x48/apps" \
        "/run/current-system/sw/share/pixmaps"; do
        for ext in svg png xpm; do
            f="$dir/${name}.${ext}"
            [[ -f "$f" ]] && echo "$f" && return
        done
    done
    # Fall back to name (let Qt try its theme lookup)
    echo "$name"
}

url_decode() {
    python3 -c "
import sys, urllib.parse
data = sys.stdin.buffer.read().decode('utf-8', errors='replace').strip()
print(urllib.parse.unquote(data))
" 2>/dev/null || cat
}

get_param() {
    local params="$1" key="$2"
    echo "$params" | tr '&' '\n' | grep -m1 "^${key}=" | cut -d= -f2- | url_decode
}

is_running() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(awk 'NR==1' "$PID_FILE" 2>/dev/null)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
        rm -f "$PID_FILE"
    fi
    return 1
}

get_active_config() {
    if [[ -f "$PID_FILE" ]]; then
        awk 'NR==2' "$PID_FILE" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

stop_singbox() {
    if is_running; then
        local pid
        pid=$(awk 'NR==1' "$PID_FILE" 2>/dev/null)
        kill "$pid" 2>/dev/null || true
        rm -f "$PID_FILE"
    fi
    pkill -f "sing-box run" 2>/dev/null || true
    sleep 0.2
}

make_base_config() {
    echo '{
        "log": {"level": "info", "timestamp": true},
        "inbounds": [{
            "type": "tun",
            "tag": "tun-in",
            "address": "172.19.0.1/30",
            "stack": "mixed",
            "auto_route": true
        }],
        "experimental": {
            "cache_file": {"enabled": true}
        }
    }'
}

# ─── commands ─────────────────────────────────────────────────────────────────

case "$cmd" in

    # ── status ────────────────────────────────────────────────────────────────
    status)
        if is_running; then
            pid=$(awk 'NR==1' "$PID_FILE")
            active=$(get_active_config)
            active_name=$(basename "$active" .json 2>/dev/null || echo "")
            echo "running:${pid}:${active_name}"
        else
            echo "stopped"
        fi
        ;;

    # ── list ──────────────────────────────────────────────────────────────────
    list)
        active=$(get_active_config)
        first=true
        printf '['
        while IFS= read -r -d '' f; do
            # skip broken symlinks
            [[ -r "$f" ]] || continue
            name=$(basename "$f" .json)
            type=$(jq -r '
                (.outbounds // [])[] |
                select(.type != "direct" and .type != "block" and .type != "dns") |
                .type' "$f" 2>/dev/null | head -1 || true)
            [[ -z "$type" || "$type" == "null" ]] && type="unknown"
            is_active="false"
            [[ "$f" == "$active" ]] && is_active="true"
            saved_apps=$(cat "$APPS_DIR/${name}.json" 2>/dev/null || echo "[]")
            $first || printf ','
            first=false
            printf '{"name":%s,"path":%s,"type":%s,"isActive":%s,"savedApps":%s}' \
                "$(jq -Rn --arg v "$name" '$v')" \
                "$(jq -Rn --arg v "$f"    '$v')" \
                "$(jq -Rn --arg v "$type" '$v')" \
                "$is_active" \
                "$saved_apps"
        done < <(find "$SING_BOX_DIR" -maxdepth 1 -name "*.json" -print0 2>/dev/null | sort -z || true)
        printf ']\n'
        ;;

    # ── start ─────────────────────────────────────────────────────────────────
    start)
        config_path="${1:-}"
        apps_json="${2:-[]}"

        [[ -z "$config_path" || ! -f "$config_path" ]] && {
            echo "error:Config not found: $config_path" >&2; exit 1
        }

        stop_singbox

        # sing-box 1.12+ requires this for configs with legacy DNS format
        export ENABLE_DEPRECATED_LEGACY_DNS_SERVERS=true

        # If no apps explicitly passed, try to load saved selection for this profile
        profile_name=$(basename "$config_path" .json)
        if [[ "$apps_json" == "[]" || -z "$apps_json" ]]; then
            apps_json=$(cat "$APPS_DIR/${profile_name}.json" 2>/dev/null || echo "[]")
        fi

        if [[ "$apps_json" != "[]" && "$apps_json" != "null" && -n "$apps_json" ]]; then
            # Per-app mode: ONLY selected apps go through proxy, everything else is direct
            proxy_tag=$(jq -r '
                (.outbounds // [])[] |
                select(.type != "direct" and .type != "block" and .type != "dns") |
                .tag' "$config_path" 2>/dev/null | head -1)
            [[ -z "$proxy_tag" || "$proxy_tag" == "null" ]] && proxy_tag="proxy"

            # Convert exec names → real process names (follows nix wrapper chains)
            # Apps saved as exec names from desktop files; sing-box needs actual ELF basename
            proc_names_arr=()
            while IFS= read -r exec_name; do
                [[ -z "$exec_name" ]] && continue
                resolved=$(resolve_proc_name "$exec_name")
                # Reject unresolved shell variables or empty results → keep original name
                if [[ -z "$resolved" || "$resolved" == \$* || "$resolved" == *'$'* ]]; then
                    resolved="$exec_name"
                fi
                proc_names_arr+=("$resolved")
            done < <(echo "$apps_json" | jq -r '.[]' 2>/dev/null)
            proc_names_json=$(printf '%s\n' "${proc_names_arr[@]}" | jq -R . | jq -s .)

            jq --argjson apps "$proc_names_json" --arg tag "$proxy_tag" '
                .route = (.route // {}) + {
                    "auto_detect_interface": true,
                    "rules": [
                        {"ip_is_private": true, "outbound": "direct"},
                        {"process_name": $apps, "outbound": $tag},
                        {"outbound": "direct"}
                    ]
                }
            ' "$config_path" > "$TMP_CONFIG"
            nohup sing-box run -c "$TMP_CONFIG" >"$LOG_FILE" 2>&1 &
        else
            # Full-proxy mode: all traffic through proxy
            nohup sing-box run -c "$config_path" >"$LOG_FILE" 2>&1 &
        fi

        local_pid=$!
        printf '%s\n%s\n' "$local_pid" "$config_path" > "$PID_FILE"
        echo "started:${local_pid}"
        ;;

    # ── stop ──────────────────────────────────────────────────────────────────
    stop)
        stop_singbox
        rm -f "$TMP_CONFIG"
        echo "stopped"
        ;;

    # ── import ────────────────────────────────────────────────────────────────
    import)
        url="${1:-}"
        [[ -z "$url" ]] && { echo "error:No URL provided" >&2; exit 1; }

        proto="${url%%://*}"
        rest="${url#*://}"

        # Extract fragment as name
        if echo "$rest" | grep -q '#'; then
            name=$(printf '%s' "${rest##*#}" | url_decode)
            rest="${rest%#*}"
        else
            name=""
        fi

        # Extract query params
        if echo "$rest" | grep -q '\?'; then
            params="${rest#*\?}"
            rest="${rest%%\?*}"
        else
            params=""
        fi

        case "$proto" in
            vless)
                uuid="${rest%%@*}"
                hostport="${rest#*@}"
                host="${hostport%%:*}"
                port="${hostport#*:}"

                security=$(get_param "$params" "security")
                ttype=$(get_param "$params"    "type")
                sni=$(get_param "$params"      "sni")
                pbk=$(get_param "$params"      "pbk")
                sid=$(get_param "$params"      "sid")
                fp=$(get_param "$params"       "fp")
                svc=$(get_param "$params"      "serviceName")
                wspath=$(get_param "$params"   "path")
                wshost=$(get_param "$params"   "host")
                [[ -z "$name" ]] && name="vless-$(date +%s)"

                jq -n \
                    --arg uuid "$uuid" --arg server "$host" \
                    --argjson port "$(echo "$port" | grep -oE '[0-9]+' | head -1 || echo 443)" \
                    --arg security "$security" --arg ttype "$ttype" \
                    --arg sni "$sni" --arg pbk "$pbk" --arg sid "$sid" --arg fp "$fp" \
                    --arg svc "$svc" --arg wspath "$wspath" --arg wshost "$wshost" \
                    '
                    (if $security == "reality" then {
                        "tls": {
                            "enabled": true, "server_name": $sni, "insecure": false,
                            "utls": {"enabled": true, "fingerprint": (if $fp != "" then $fp else "chrome" end)},
                            "reality": {"enabled": true, "public_key": $pbk, "short_id": $sid}
                        }
                    } elif $security == "tls" then {
                        "tls": {"enabled": true, "server_name": $sni, "insecure": false}
                    } else {} end) as $tls |
                    (if $ttype == "grpc" then {"transport": {"type": "grpc", "service_name": $svc}}
                     elif $ttype == "ws" then {"transport": {"type": "ws", "path": $wspath,
                         "headers": (if $wshost != "" then {"Host": $wshost} else {} end)}}
                     elif $ttype == "http" then {"transport": {"type": "http", "path": [$wspath]}}
                     else {} end) as $transport |
                    {
                        "log": {"level": "info", "timestamp": true},
                        "inbounds": [{"type":"tun","tag":"tun-in","address":"172.19.0.1/30",
                            "stack":"mixed","auto_route":true}],
                        "outbounds": [
                            ({"type":"vless","tag":"proxy","server":$server,
                              "server_port":$port,"uuid":$uuid,"packet_encoding":"xudp"}
                             + $tls + $transport),
                            {"type":"direct","tag":"direct"},
                            {"type":"block","tag":"block"}
                        ],
                        "route": {
                            "auto_detect_interface": true,
                            "rules": [
                                {"ip_is_private": true, "outbound": "direct"},
                                {"inbound": "tun-in", "outbound": "proxy"}
                            ]
                        },
                        "experimental": {"cache_file": {"enabled": true}}
                    }'
                ;;

            hysteria2|hy2)
                password="${rest%%@*}"
                hostport="${rest#*@}"
                host="${hostport%%:*}"
                port="${hostport#*:}"
                insecure=$(get_param "$params" "insecure")
                obfs_type=$(get_param "$params" "obfs")
                obfs_pass=$(get_param "$params" "obfs-password")
                sni=$(get_param "$params" "sni")
                [[ -z "$name" ]] && name="hysteria2-$(date +%s)"

                jq -n \
                    --arg password "$password" --arg server "$host" \
                    --argjson port "$(echo "$port" | grep -oE '[0-9]+' | head -1 || echo 443)" \
                    --argjson insecure "$([ "$insecure" = "1" ] && echo true || echo false)" \
                    --arg obfs_type "$obfs_type" --arg obfs_pass "$obfs_pass" --arg sni "$sni" \
                    '
                    (if $obfs_type != "" then {"obfs": {"type": $obfs_type, "password": $obfs_pass}} else {} end) as $obfs |
                    {
                        "log": {"level": "info", "timestamp": true},
                        "inbounds": [{"type":"tun","tag":"tun-in","address":"172.19.0.1/30",
                            "stack":"mixed","auto_route":true}],
                        "outbounds": [
                            ({"type":"hysteria2","tag":"proxy","server":$server,
                              "server_port":$port,"password":$password,
                              "tls":{"enabled":true,"insecure":$insecure,
                                     "server_name":(if $sni != "" then $sni else null end)}}
                             + $obfs),
                            {"type":"direct","tag":"direct"},
                            {"type":"block","tag":"block"}
                        ],
                        "route": {
                            "auto_detect_interface": true,
                            "rules": [
                                {"ip_is_private": true, "outbound": "direct"},
                                {"inbound": "tun-in", "outbound": "proxy"}
                            ]
                        },
                        "experimental": {"cache_file": {"enabled": true}}
                    }'
                ;;

            trojan)
                password="${rest%%@*}"
                hostport="${rest#*@}"
                host="${hostport%%:*}"
                port="${hostport#*:}"
                sni=$(get_param "$params" "sni")
                [[ -z "$sni" ]] && sni="$host"
                insecure=$(get_param "$params" "allowInsecure")
                [[ -z "$name" ]] && name="trojan-$(date +%s)"

                jq -n \
                    --arg password "$password" --arg server "$host" \
                    --argjson port "$(echo "$port" | grep -oE '[0-9]+' | head -1 || echo 443)" \
                    --arg sni "$sni" \
                    --argjson insecure "$([ "$insecure" = "1" ] && echo true || echo false)" \
                    '{
                        "log": {"level": "info", "timestamp": true},
                        "inbounds": [{"type":"tun","tag":"tun-in","address":"172.19.0.1/30",
                            "stack":"mixed","auto_route":true}],
                        "outbounds": [
                            {"type":"trojan","tag":"proxy","server":$server,"server_port":$port,
                             "password":$password,"tls":{"enabled":true,"server_name":$sni,"insecure":$insecure}},
                            {"type":"direct","tag":"direct"},
                            {"type":"block","tag":"block"}
                        ],
                        "route": {
                            "auto_detect_interface": true,
                            "rules": [
                                {"ip_is_private": true, "outbound": "direct"},
                                {"inbound": "tun-in", "outbound": "proxy"}
                            ]
                        },
                        "experimental": {"cache_file": {"enabled": true}}
                    }'
                ;;

            ss)
                if echo "$rest" | grep -q '@'; then
                    userinfo_b64="${rest%%@*}"
                    hostport="${rest#*@}"
                    host="${hostport%%:*}"
                    port="${hostport#*:}"
                    userinfo=$(echo "$userinfo_b64=" | base64 -d 2>/dev/null || echo "$userinfo_b64")
                    method="${userinfo%%:*}"
                    ss_pass="${userinfo#*:}"
                else
                    decoded=$(printf '%s==' "$rest" | base64 -d 2>/dev/null || echo "")
                    userinfo="${decoded%%@*}"
                    hostport="${decoded#*@}"
                    host="${hostport%%:*}"
                    port="${hostport#*:}"
                    method="${userinfo%%:*}"
                    ss_pass="${userinfo#*:}"
                fi
                [[ -z "$name" ]] && name="ss-$(date +%s)"

                jq -n \
                    --arg method "$method" --arg password "$ss_pass" \
                    --arg server "$host" \
                    --argjson port "$(echo "$port" | grep -oE '[0-9]+' | head -1 || echo 443)" \
                    '{
                        "log": {"level": "info", "timestamp": true},
                        "inbounds": [{"type":"tun","tag":"tun-in","address":"172.19.0.1/30",
                            "stack":"mixed","auto_route":true}],
                        "outbounds": [
                            {"type":"shadowsocks","tag":"proxy","server":$server,
                             "server_port":$port,"method":$method,"password":$password},
                            {"type":"direct","tag":"direct"},
                            {"type":"block","tag":"block"}
                        ],
                        "route": {
                            "auto_detect_interface": true,
                            "rules": [
                                {"ip_is_private": true, "outbound": "direct"},
                                {"inbound": "tun-in", "outbound": "proxy"}
                            ]
                        },
                        "experimental": {"cache_file": {"enabled": true}}
                    }'
                ;;

            vmess)
                decoded=$(printf '%s' "$rest" | base64 -d 2>/dev/null)
                [[ -z "$decoded" ]] && { echo "error:Failed to decode vmess URL" >&2; exit 1; }

                name=$(echo "$decoded" | jq -r '.ps // "vmess"' 2>/dev/null)
                [[ -z "$name" ]] && name="vmess-$(date +%s)"

                echo "$decoded" | jq '
                    (if .tls == "tls" then
                        {"tls": {"enabled": true, "server_name": (.sni // .host // .add), "insecure": false}}
                    else {} end) as $tls |
                    (if .net == "grpc" then {"transport": {"type": "grpc", "service_name": (.path // "")}}
                     elif .net == "ws" then {"transport": {"type": "ws", "path": (.path // "/"),
                         "headers": (if (.host // "") != "" then {"Host": .host} else {} end)}}
                     elif .net == "http" then {"transport": {"type": "http", "path": [(.path // "/")]}}
                     else {} end) as $transport |
                    {
                        "log": {"level": "info", "timestamp": true},
                        "inbounds": [{"type":"tun","tag":"tun-in","address":"172.19.0.1/30",
                            "stack":"mixed","auto_route":true}],
                        "outbounds": [
                            ({"type":"vmess","tag":"proxy","server":.add,
                              "server_port":(.port | tonumber),
                              "uuid":.id, "security":(.scy // "auto"),
                              "alter_id":((.aid // "0") | tonumber)}
                             + $tls + $transport),
                            {"type":"direct","tag":"direct"},
                            {"type":"block","tag":"block"}
                        ],
                        "route": {
                            "auto_detect_interface": true,
                            "rules": [
                                {"ip_is_private": true, "outbound": "direct"},
                                {"inbound": "tun-in", "outbound": "proxy"}
                            ]
                        },
                        "experimental": {"cache_file": {"enabled": true}}
                    }'
                ;;

            *)
                echo "error:Unsupported protocol: $proto" >&2
                exit 1
                ;;
        esac | (
            safe_name=$(echo "$name" | sed 's/[^a-zA-Z0-9._-]/-/g' | sed 's/^-*//' | cut -c1-80)
            [[ -z "$safe_name" ]] && safe_name="${proto}-$(date +%s)"
            out_path="$SING_BOX_DIR/${safe_name}.json"
            # Read stdin into the file
            jq '.' > "$out_path"
            printf 'imported:%s\t%s\n' "$name" "$out_path"
        )
        ;;

    # ── list-apps ─────────────────────────────────────────────────────────────
    list-apps)
        # Collect all applications directories from XDG spec + NixOS-specific paths
        declare -a app_dirs=()
        # XDG_DATA_HOME (default ~/.local/share)
        xdg_home="${XDG_DATA_HOME:-$HOME/.local/share}"
        app_dirs+=("$xdg_home/applications")
        # NixOS user profile (most user apps live here)
        app_dirs+=("$HOME/.nix-profile/share/applications")
        # System-wide paths
        app_dirs+=("/run/current-system/sw/share/applications")
        app_dirs+=("/etc/profiles/per-user/$USER/share/applications")
        # Remaining XDG_DATA_DIRS entries
        if [[ -n "${XDG_DATA_DIRS:-}" ]]; then
            while IFS= read -r dir; do
                [[ -d "$dir/applications" ]] && app_dirs+=("$dir/applications")
            done < <(echo "$XDG_DATA_DIRS" | tr ':' '\n')
        fi

        first=true
        printf '['
        declare -A seen
        for app_dir in "${app_dirs[@]}"; do
            [[ -d "$app_dir" ]] || continue
            while IFS= read -r -d '' f; do
                [[ -r "$f" ]] || continue
                # Skip [Desktop Action] sections — only parse [Desktop Entry]
                name=$(awk '/^\[Desktop Entry\]/{found=1} found && /^Name=/{sub(/^Name=/,""); print; exit}' "$f" 2>/dev/null | tr -d '\r\n')
                exec_line=$(awk '/^\[Desktop Entry\]/{found=1} found && /^Exec=/{sub(/^Exec=/,""); print; exit}' "$f" 2>/dev/null | tr -d '\r\n')
                nodisplay=$(awk '/^\[Desktop Entry\]/{found=1} found && /^NoDisplay=/{sub(/^NoDisplay=/,""); print; exit}' "$f" 2>/dev/null | tr -d '\r\n')
                type=$(awk '/^\[Desktop Entry\]/{found=1} found && /^Type=/{sub(/^Type=/,""); print; exit}' "$f" 2>/dev/null | tr -d '\r\n')
                icon=$(awk '/^\[Desktop Entry\]/{found=1} found && /^Icon=/{sub(/^Icon=/,""); print; exit}' "$f" 2>/dev/null | tr -d '\r\n')

                # Only include Application type, skip hidden and empty
                [[ "$type" != "Application" && -n "$type" ]] && continue
                [[ "$nodisplay" == "true" ]] && continue
                [[ -z "$name" || -z "$exec_line" ]] && continue

                # Extract binary name (strip path, args, %placeholders)
                exec_bin=$(echo "$exec_line" | awk '{print $1}' | sed 's|.*/||; s/%[a-zA-Z]//g; s/"//g')
                [[ -z "$exec_bin" ]] && continue

                # Deduplicate by binary name
                [[ -n "${seen[$exec_bin]+_}" ]] && continue
                seen[$exec_bin]=1

                # Resolve icon name to absolute file path for reliable display
                icon_path=$(resolve_icon "${icon:-}")
                # Resolve real process name (follows nix wrapper chains to ELF)
                proc_name=$(resolve_proc_name "$exec_bin")

                $first || printf ','
                first=false
                printf '{"name":%s,"exec":%s,"procName":%s,"icon":%s}' \
                    "$(jq -Rn --arg v "$name"      '$v')" \
                    "$(jq -Rn --arg v "$exec_bin"  '$v')" \
                    "$(jq -Rn --arg v "$proc_name" '$v')" \
                    "$(jq -Rn --arg v "$icon_path" '$v')"
            done < <(find "$app_dir" -maxdepth 1 -name "*.desktop" -print0 2>/dev/null | sort -z)
        done
        printf ']\n'
        ;;

    # ── save-apps ─────────────────────────────────────────────────────────────
    save-apps)
        profile_name="${1:-}"
        apps_json="${2:-[]}"
        [[ -z "$profile_name" ]] && { echo "error:No profile name" >&2; exit 1; }
        echo "$apps_json" > "$APPS_DIR/${profile_name}.json"
        echo "saved"
        ;;

    # ── delete ────────────────────────────────────────────────────────────────
    delete)
        path="${1:-}"
        [[ -z "$path" || ! -f "$path" ]] && { echo "error:File not found: $path" >&2; exit 1; }
        # Stop sing-box if this config is active
        active=$(get_active_config)
        [[ "$path" == "$active" ]] && stop_singbox
        rm -f "$path"
        echo "deleted"
        ;;

    *)
        echo "error:Unknown command: $cmd" >&2
        exit 1
        ;;
esac
