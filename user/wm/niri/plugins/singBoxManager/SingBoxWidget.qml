import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    // Initial height; updated reactively via Binding in ccDetailContent
    ccDetailHeight: 310

    // ── state ──────────────────────────────────────────────────────────────
    property bool   isRunning:  false
    property string activeName: ""
    property var    profiles:   []
    // In-session app selection cache: profileName → string[]
    // Updated immediately on change; also persisted to disk via save-apps
    property var    _appsCache: ({})

    readonly property string _script: Qt.resolvedUrl("./singbox-manager.sh")
                                        .toString().replace("file://", "")

    // ── status polling ──────────────────────────────────────────────────────
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: { _statusProc.running = true }
    }

    Process {
        id: _statusProc
        command: ["bash", root._script, "status"]
        stdout: SplitParser {
            onRead: function(line) {
                if (line.startsWith("running:")) {
                    root.isRunning  = true
                    const parts     = line.split(":")
                    root.activeName = parts.length > 2 ? parts[2] : ""
                } else {
                    root.isRunning  = false
                    root.activeName = ""
                }
            }
        }
        onExited: function(_) { _statusProc.running = false }
    }

    Process {
        id: _listProc
        command: ["bash", root._script, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.profiles = JSON.parse(text.trim()) } catch (e) {}
            }
        }
        onExited: function(_) { _listProc.running = false }
    }

    Component.onCompleted: {
        _statusProc.running = true
        _listProc.running   = true
    }

    // ── helpers ────────────────────────────────────────────────────────────
    function startConfig(path) {
        const profileName = path.split("/").pop().replace(".json", "")
        // Prefer in-session cache, fall back to script-loaded savedApps
        const cached = root._appsCache[profileName]
        const fromScript = (root.profiles.find(p => p.name === profileName) || {}).savedApps || []
        const apps = cached !== undefined ? cached : fromScript
        _startProc.configPath = path
        _startProc.appsJson   = JSON.stringify(apps)
        _startProc.running    = true
    }

    function stopAll() { _stopProc.running = true }
    function refreshProfiles() { _listProc.running = true }

    function saveApps(profileName, apps) {
        // Update in-session cache
        const c = Object.assign({}, root._appsCache)
        c[profileName] = apps
        root._appsCache = c
        // Persist to disk via script
        _saveAppsProc.pendingName = profileName
        _saveAppsProc.pendingApps = JSON.stringify(apps)
        _saveAppsProc.running = true
    }

    function getAppsForProfile(modelData) {
        const cached = root._appsCache[modelData.name]
        if (cached !== undefined) return cached
        return modelData.savedApps || []
    }

    // ── processes ──────────────────────────────────────────────────────────
    Process {
        id: _startProc
        property string configPath: ""
        property string appsJson:   "[]"
        command: ["bash", root._script, "start", configPath, appsJson]
        stdout: SplitParser {
            onRead: function(line) {
                if (line.startsWith("started:")) {
                    root.isRunning  = true
                    root.activeName = _startProc.configPath
                                          .split("/").pop().replace(".json", "")
                    ToastService.showInfo("Sing-box", "Connected: " + root.activeName)
                }
            }
        }
        stderr: SplitParser {
            onRead: function(line) {
                if (line.startsWith("error:"))
                    ToastService.showError("Sing-box", line.substring(6))
            }
        }
        onExited: function(_) { _startProc.running = false; root.refreshProfiles() }
    }

    Process {
        id: _saveAppsProc
        property string pendingName: ""
        property string pendingApps: "[]"
        command: ["bash", root._script, "save-apps", pendingName, pendingApps]
        onExited: function(_) { _saveAppsProc.running = false }
    }

    Process {
        id: _stopProc
        command: ["bash", root._script, "stop"]
        onExited: _ => {
            _stopProc.running   = false
            root.isRunning      = false
            root.activeName     = ""
            ToastService.showInfo("Sing-box", "Disconnected")
        }
    }

    // ── CC tile ────────────────────────────────────────────────────────────
    ccWidgetIcon:          isRunning ? "vpn_lock" : "vpn_key_off"
    ccWidgetPrimaryText:   "Sing-box"
    ccWidgetSecondaryText: isRunning ? (activeName || "Running") : "Disconnected"
    ccWidgetIsActive:      isRunning

    onCcWidgetToggled: {
        if (isRunning) {
            stopAll()
        } else {
            const active = profiles.find(p => p.isActive)
            const target = active || (profiles.length > 0 ? profiles[0] : null)
            if (target) startConfig(target.path)
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    // Inline component: App Selector
    // ══════════════════════════════════════════════════════════════════════
    component AppSelectorPanel: Item {
        id: appSel

        property string scriptPath:   ""
        property string profileName:  ""
        property var    initialApps:  []

        signal selectionChanged(var apps)

        property var    _allApps: []
        property var    _selected: ({})
        property string _filter:  ""
        property bool   _loading: false

        onProfileNameChanged: { _filter = "" }

        readonly property var _filtered: {
            const q = _filter.toLowerCase()
            const base = q === ""
                ? _allApps.slice()
                : _allApps.filter(a =>
                    a.name.toLowerCase().includes(q) ||
                    a.exec.toLowerCase().includes(q))
            // Selected apps float to top; within each group sort alphabetically
            return base.sort((a, b) => {
                const aOn = !!appSel._selected[a.exec]
                const bOn = !!appSel._selected[b.exec]
                if (aOn !== bOn) return aOn ? -1 : 1
                return a.name.localeCompare(b.name)
            })
        }

        implicitHeight: _appSelCol.implicitHeight
        height: implicitHeight

        Process {
            id: _appsProc
            command: ["bash", appSel.scriptPath, "list-apps"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try { appSel._allApps = JSON.parse(text.trim()) } catch (e) { appSel._allApps = [] }
                    appSel._loading = false
                }
            }
            stderr: SplitParser { onRead: _ => { appSel._loading = false } }
            onExited: _ => { _appsProc.running = false }
        }

        onVisibleChanged: {
            if (visible && _allApps.length === 0) {
                _loading = true
                _appsProc.running = true
            }
        }

        onInitialAppsChanged: {
            const sel = {}
            for (const exec of (initialApps || [])) sel[exec] = true
            _selected = sel
        }

        function _toggle(exec) {
            const sel = Object.assign({}, _selected)
            if (sel[exec]) delete sel[exec]; else sel[exec] = true
            _selected = sel
            selectionChanged(Object.keys(sel))
        }

        Column {
            id: _appSelCol
            width: parent.width
            spacing: 0

            // Top divider
            Rectangle {
                width: parent.width; height: 1
                color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
            }

            // Rounded container wrapping header + search + list
            Rectangle {
                width: parent.width
                height: _innerSection.implicitHeight
                color: Theme.withAlpha(Theme.surfaceVariant, 0.06)
                radius: Theme.cornerRadius

                Column {
                    id: _innerSection
                    width: parent.width
                    spacing: Theme.spacingXS
                    topPadding: Theme.spacingS
                    bottomPadding: Theme.spacingS

                    RowLayout {
                        width: parent.width - Theme.spacingM * 2
                        x: Theme.spacingM
                        spacing: Theme.spacingS
                        DankIcon { name: "apps"; size: 14; color: Theme.surfaceVariantText; Layout.alignment: Qt.AlignVCenter }
                        StyledText {
                            text: "Route apps through proxy"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceVariantText
                            Layout.fillWidth: true
                        }
                        StyledText {
                            visible: Object.keys(appSel._selected).length > 0
                            text: Object.keys(appSel._selected).length + " selected"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.primary
                        }
                    }

                    DankTextField {
                        width: parent.width - Theme.spacingM * 2
                        x: Theme.spacingM
                        placeholderText: "Search apps…"
                        text: appSel._filter
                        onTextChanged: appSel._filter = text
                        leftIconName: "search"
                        leftIconSize: 16
                        leftIconColor: Theme.surfaceVariantText
                    }

                    Item {
                        visible: appSel._loading
                        width: parent.width; height: 40
                        Row {
                            anchors.centerIn: parent; spacing: Theme.spacingS
                            DankIcon { name: "sync"; size: 16; color: Theme.surfaceVariantText }
                            StyledText { text: "Loading apps…"; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }

                    // Scrollable list — full width, rounded clip container
                    Rectangle {
                        visible: !appSel._loading && appSel._allApps.length > 0
                        width: parent.width
                        height: Math.min(_innerCol.implicitHeight + Theme.spacingS * 2, 160)
                        radius: Theme.cornerRadius - 2
                        clip: true
                        color: "transparent"

                        DankFlickable {
                            anchors.fill: parent
                            contentWidth: width
                            contentHeight: _innerCol.implicitHeight + Theme.spacingS * 2

                            Column {
                                id: _innerCol
                                width: parent.width
                                spacing: 2
                                topPadding: Theme.spacingXS
                                bottomPadding: Theme.spacingS

                        Repeater {
                            model: appSel._filtered
                            delegate: Rectangle {
                                id: _appItem
                                required property var modelData
                                readonly property bool _checked: !!appSel._selected[modelData.exec]
                                width: _innerCol.width; height: 34; radius: Theme.cornerRadius - 2
                                color: _appHover.containsMouse
                                    ? Theme.primaryHoverLight
                                    : (_checked ? Theme.withAlpha(Theme.primary, 0.08) : "transparent")

                                RowLayout {
                                    anchors { fill: parent; leftMargin: Theme.spacingS; rightMargin: Theme.spacingS }
                                    spacing: Theme.spacingS

                                    // Checkbox
                                    Rectangle {
                                        width: 16; height: 16; radius: 4
                                        color: _appItem._checked ? Theme.primary : "transparent"
                                        border.width: 1.5
                                        border.color: _appItem._checked ? Theme.primary : Theme.outline
                                        Layout.alignment: Qt.AlignVCenter
                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: "check"; size: 10
                                            color: Theme.onPrimary
                                            visible: _appItem._checked
                                        }
                                    }

                                    // App icon (resolved to absolute path by script)
                                    Item {
                                        width: 20; height: 20
                                        Layout.alignment: Qt.AlignVCenter
                                        Image {
                                            id: _iconImg
                                            anchors.fill: parent
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                            source: {
                                                const ic = modelData.icon || ""
                                                if (ic === "") return ""
                                                // Absolute path from resolve_icon in script
                                                if (ic.startsWith("/")) return "file://" + ic
                                                // Named icon fallback via Qt theme
                                                return "image://icon/" + ic
                                            }
                                        }
                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: "apps"; size: 16
                                            color: Theme.surfaceVariantText
                                            visible: _iconImg.status !== Image.Ready
                                        }
                                    }

                                    // App name
                                    StyledText {
                                        text: modelData.name
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: _appItem._checked ? Theme.primary : Theme.surfaceText
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    // Exec name (muted)
                                    StyledText {
                                        text: modelData.exec
                                        font.pixelSize: Theme.fontSizeSmall - 1
                                        color: Theme.surfaceVariantText
                                        elide: Text.ElideRight
                                        Layout.preferredWidth: 80
                                    }
                                }

                                MouseArea {
                                    id: _appHover
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: appSel._toggle(modelData.exec)
                                }
                            }
                        }
                    }
                }
                    } // Rectangle (scrollable list)

                    StyledText {
                        visible: !appSel._loading && appSel._allApps.length > 0 && appSel._filtered.length === 0
                        text: "No matching apps"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        width: parent.width - Theme.spacingM * 2
                        x: Theme.spacingM
                        topPadding: Theme.spacingS
                        bottomPadding: Theme.spacingS
                    }

                } // Column _innerSection
            } // Rectangle rounded container
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    // Inline component: Profile row
    // ══════════════════════════════════════════════════════════════════════
    component ProfileDelegate: Rectangle {
        id: pd

        required property var    profile
        property bool            isActive:     false
        property bool            isAppsActive: false  // apps panel open for this profile
        property var             savedApps:    []

        signal connectClicked()
        signal disconnectClicked()
        signal deleteClicked()
        signal toggleApps()

        width: parent ? parent.width : 400
        height: 52
        radius: Theme.cornerRadius
        color: isActive ? Theme.primaryPressed : Theme.surfaceLight
        border.width: isActive ? 2 : 1
        border.color: isActive ? Theme.primary : (isAppsActive ? Theme.primary : Theme.outlineLight)

        DankIcon {
            id: _pdIcon
            name: pd.isActive ? "vpn_lock" : "vpn_key_off"
            size: 20
            color: pd.isActive ? Theme.primary : Theme.surfaceText
            anchors { left: parent.left; leftMargin: Theme.spacingM; verticalCenter: parent.verticalCenter }
        }

        Column {
            spacing: 2
            anchors {
                left: _pdIcon.right; leftMargin: Theme.spacingS
                right: _pdBtns.left; rightMargin: Theme.spacingS
                verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: pd.profile?.name ?? ""
                font.pixelSize: Theme.fontSizeMedium
                color: pd.isActive ? Theme.primary : Theme.surfaceText
                elide: Text.ElideRight; wrapMode: Text.NoWrap; width: parent.width
            }
            StyledText {
                text: pd.profile?.type ?? "unknown"
                font.pixelSize: Theme.fontSizeSmall
                color: pd.isActive ? Theme.primaryContainer : Theme.surfaceVariantText
                wrapMode: Text.NoWrap; width: parent.width; elide: Text.ElideRight
            }
        }

        Row {
            id: _pdBtns
            spacing: 2
            anchors { right: parent.right; rightMargin: Theme.spacingS; verticalCenter: parent.verticalCenter }

            // Apps toggle button
            Rectangle {
                width: 28; height: 28; radius: 14
                color: _appsHov.containsMouse ? Theme.surfacePressed : (pd.isAppsActive ? Theme.withAlpha(Theme.primary, 0.15) : "transparent")
                DankIcon {
                    anchors.centerIn: parent
                    name: pd.isAppsActive ? "expand_less" : "apps"
                    size: 16
                    color: (pd.isAppsActive || pd.savedApps.length > 0) ? Theme.primary : Theme.surfaceVariantText
                }
                MouseArea {
                    id: _appsHov; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pd.toggleApps()
                }
            }

            // Connect / Stop button
            Rectangle {
                width: 28; height: 28; radius: 14
                color: _conHov.containsMouse ? (pd.isActive ? Theme.errorHover : Theme.primaryHoverLight) : "transparent"
                DankIcon {
                    anchors.centerIn: parent
                    name: pd.isActive ? "stop" : "play_arrow"
                    size: 18
                    color: pd.isActive ? Theme.error : Theme.primary
                }
                MouseArea {
                    id: _conHov; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pd.isActive ? pd.disconnectClicked() : pd.connectClicked()
                }
            }

            // Delete button
            Rectangle {
                width: 28; height: 28; radius: 14
                color: _delHov.containsMouse ? Theme.errorHover : "transparent"
                DankIcon {
                    anchors.centerIn: parent
                    name: "delete"; size: 16
                    color: _delHov.containsMouse ? Theme.error : Theme.surfaceVariantText
                }
                MouseArea {
                    id: _delHov; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pd.deleteClicked()
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    // Inline component: Detail Content
    // ══════════════════════════════════════════════════════════════════════
    component DetailContent: Rectangle {
        id: dc

        property bool   isRunning:  false
        property string activeName: ""
        property var    profiles:   []
        property string scriptPath: ""
        property var    pluginSvc:  null
        property string pluginId:   ""
        property var    pluginData: ({})
        // Function ref for getting apps (resolves cache + savedApps from script)
        property var    appsForProfile: null

        signal startRequested(string path)
        signal stopRequested()
        signal refreshNeeded()
        signal appsChanged(string profileName, var apps)

        property string expandedProfile: ""
        property bool   importOpen:      false
        property string importUrl:       ""
        property bool   importing:       false
        property string importError:     ""

        implicitHeight: _mainCol.implicitHeight + Theme.spacingM * 2
        clip: true
        radius: Theme.cornerRadius
        color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)

        // pending URL stored separately so command binding is stable
        property string _pendingUrl: ""
        property string _pendingDelete: ""

        Process {
            id: _importProc
            command: ["bash", dc.scriptPath, "import", dc._pendingUrl]
            stdout: SplitParser {
                onRead: function(line) {
                    if (line.startsWith("imported:")) {
                        const tab  = line.indexOf("\t")
                        const name = tab >= 0 ? line.substring(9, tab) : line.substring(9)
                        dc.importUrl   = ""
                        dc._pendingUrl = ""
                        dc.importOpen  = false
                        dc.importing   = false
                        dc.importError = ""
                        dc.refreshNeeded()
                        ToastService.showInfo("Sing-box", "Imported: " + name)
                    }
                }
            }
            stderr: SplitParser {
                onRead: function(line) {
                    if (line.startsWith("error:")) { dc.importError = line.substring(6); dc.importing = false }
                }
            }
            onExited: function(code) {
                _importProc.running = false
                dc.importing = false
                if (code !== 0 && dc.importError === "")
                    dc.importError = "Import failed (exit " + code + ")"
            }
        }

        Process {
            id: _deleteProc
            command: ["bash", dc.scriptPath, "delete", dc._pendingDelete]
            stdout: SplitParser {
                onRead: function(line) {
                    if (line === "deleted") {
                        dc.refreshNeeded()
                        ToastService.showInfo("Sing-box", "Profile deleted")
                    }
                }
            }
            stderr: SplitParser {
                onRead: function(line) {
                    if (line.startsWith("error:"))
                        ToastService.showError("Sing-box", line.substring(6))
                }
            }
            onExited: function(_) { _deleteProc.running = false }
        }

        function doImport() {
            const u = importUrl.trim()
            if (u === "") return
            importError    = ""
            importing      = true
            _pendingUrl    = u
            _importProc.running = true
        }

        function doDelete(path) {
            _pendingDelete     = path
            _deleteProc.running = true
        }

        Column {
            id: _mainCol
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: Theme.spacingM }
            spacing: Theme.spacingS

            // header row
            RowLayout {
                width: parent.width; spacing: Theme.spacingS
                StyledText {
                    text: dc.isRunning ? ("Active: " + (dc.activeName || "sing-box")) : "Active: None"
                    font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Medium; color: Theme.surfaceText
                    elide: Text.ElideRight; Layout.fillWidth: true
                }
                Rectangle {
                    height: 28; radius: 14
                    width: _impBtnRow.implicitWidth + Theme.spacingM * 2
                    color: _impBtnArea.containsMouse ? Theme.primaryHoverLight : Theme.surfaceLight
                    Layout.alignment: Qt.AlignVCenter
                    Row { id: _impBtnRow; anchors.centerIn: parent; spacing: Theme.spacingXS
                        DankIcon { name: "add"; size: Theme.fontSizeSmall; color: Theme.primary }
                        StyledText { text: "Import"; font.pixelSize: Theme.fontSizeSmall; color: Theme.primary; font.weight: Font.Medium }
                    }
                    MouseArea { id: _impBtnArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dc.importOpen = !dc.importOpen }
                }
                Rectangle {
                    visible: dc.isRunning; height: 28; radius: 14
                    width: _stopBtnRow.implicitWidth + Theme.spacingM * 2
                    color: _stopBtnArea.containsMouse ? Theme.errorHover : Theme.surfaceLight
                    Layout.alignment: Qt.AlignVCenter
                    Row { id: _stopBtnRow; anchors.centerIn: parent; spacing: Theme.spacingXS
                        DankIcon { name: "link_off"; size: Theme.fontSizeSmall; color: Theme.surfaceText }
                        StyledText { text: "Disconnect"; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText; font.weight: Font.Medium }
                    }
                    MouseArea { id: _stopBtnArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dc.stopRequested() }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12) }

            // Import panel
            Column {
                visible: dc.importOpen; width: parent.width; spacing: Theme.spacingXS; clip: true
                DankTextField {
                    width: parent.width
                    placeholderText: "vless://… or hysteria2://… or ss://… or trojan://…"
                    text: dc.importUrl
                    onTextChanged: { dc.importUrl = text; dc.importError = "" }
                    leftIconName: "link"; leftIconColor: Theme.surfaceVariantText
                }
                StyledText { visible: dc.importError !== ""; text: dc.importError; color: Theme.error; font.pixelSize: Theme.fontSizeSmall; wrapMode: Text.WordWrap; width: parent.width }
                RowLayout {
                    width: parent.width
                    Item { Layout.fillWidth: true }
                    DankButton { text: dc.importing ? "Importing…" : "Import"; enabled: !dc.importing && dc.importUrl.trim().length > 0; buttonHeight: 32; onClicked: dc.doImport() }
                }
                Rectangle { width: parent.width; height: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12) }
            }

            // Empty state
            Column {
                visible: dc.profiles.length === 0; width: parent.width
                spacing: Theme.spacingS; topPadding: Theme.spacingL; bottomPadding: Theme.spacingL
                DankIcon { name: "vpn_key_off"; size: 36; color: Theme.surfaceVariantText; anchors.horizontalCenter: parent.horizontalCenter }
                StyledText { text: "No sing-box configs"; font.pixelSize: Theme.fontSizeMedium; color: Theme.surfaceVariantText; anchors.horizontalCenter: parent.horizontalCenter }
                StyledText { text: "Click Import to add a connection URL"; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText; anchors.horizontalCenter: parent.horizontalCenter }
            }

            // Profile list — compact, scrollable, 220px max
            Item {
                visible: dc.profiles.length > 0
                width: parent.width
                height: Math.min(220, _profileCol.implicitHeight)
                clip: true

                DankFlickable {
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: _profileCol.implicitHeight

                    Column {
                        id: _profileCol
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: dc.profiles
                            ProfileDelegate {
                                required property var modelData
                                width: _profileCol.width
                                profile:      modelData
                                isActive:     dc.isRunning && modelData.name === dc.activeName
                                isAppsActive: dc.expandedProfile === modelData.name
                                savedApps:    dc.appsForProfile ? dc.appsForProfile(modelData) : (modelData.savedApps || [])
                                onConnectClicked:    function() { dc.startRequested(modelData.path) }
                                onDisconnectClicked: function() { dc.stopRequested() }
                                onDeleteClicked:     function() { dc.doDelete(modelData.path) }
                                onToggleApps: function() {
                                    dc.expandedProfile = dc.expandedProfile === modelData.name ? "" : modelData.name
                                }
                            }
                        }
                    }
                }
            }

            // App selector — fixed panel below profiles, independent of list size
            AppSelectorPanel {
                visible: dc.expandedProfile !== "" && dc.profiles.length > 0
                width: parent.width
                scriptPath:  dc.scriptPath
                profileName: dc.expandedProfile
                initialApps: {
                    const p = dc.profiles.find(function(pr) { return pr.name === dc.expandedProfile })
                    return (p && dc.appsForProfile) ? dc.appsForProfile(p) : []
                }
                onSelectionChanged: function(apps) { dc.appsChanged(dc.expandedProfile, apps) }
            }

            Item { width: 1; height: Theme.spacingXS }
        }
    }

    // ── CC detail view ─────────────────────────────────────────────────────
    ccDetailContent: Component {
        DetailContent {
            isRunning:      root.isRunning
            activeName:     root.activeName
            profiles:       root.profiles
            scriptPath:     root._script
            pluginSvc:      root.pluginService
            pluginId:       root.pluginId
            pluginData:     root.pluginData
            appsForProfile: root.getAppsForProfile

            onStartRequested:  function(path) { root.startConfig(path) }
            onStopRequested:   function() { root.stopAll() }
            onRefreshNeeded:   function() { root.refreshProfiles() }
            onAppsChanged:     function(name, apps) { root.saveApps(name, apps) }

            // Reactively resize the CC panel: collapsed=310, expanded=570
            Binding {
                target: root
                property: "ccDetailHeight"
                value: expandedProfile !== "" ? 570 : 310
            }
        }
    }
}
