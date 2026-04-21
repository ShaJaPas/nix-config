import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    function formatNetworkSpeed(bytesPerSec) {
        if (bytesPerSec < 1024) {
            return bytesPerSec.toFixed(0) + " B/s"
        } else if (bytesPerSec < 1024 * 1024) {
            return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        } else if (bytesPerSec < 1024 * 1024 * 1024) {
            return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s"
        } else {
            return (bytesPerSec / (1024 * 1024 * 1024)).toFixed(1) + " GB/s"
        }
    }

    Component.onCompleted: {
        DgopService.addRef(["network"])
    }
    Component.onDestruction: {
        DgopService.removeRef(["network"])
    }

    horizontalBarPill: Component {
        Row {
            spacing: 4

            StyledText {
                text: "↓"
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                color: Theme.info
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: DgopService.networkRxRate > 0 ? root.formatNetworkSpeed(DgopService.networkRxRate) : "0 B/s"
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                color: Theme.widgetTextColor
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideNone
                wrapMode: Text.NoWrap
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 2

            StyledText {
                text: {
                    const rate = DgopService.networkRxRate
                    if (rate < 1024) return rate.toFixed(0)
                    if (rate < 1024 * 1024) return (rate / 1024).toFixed(0) + "K"
                    return (rate / (1024 * 1024)).toFixed(0) + "M"
                }
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                color: Theme.info
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
