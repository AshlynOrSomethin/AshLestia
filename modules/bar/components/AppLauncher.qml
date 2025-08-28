import QtQuick 2.15
import QtQuick.Controls 2.15
import Quickshell
import "../../shared"

Rectangle {
    id: appLauncher

    implicitWidth: 40
    implicitHeight: Math.max(280, appList.contentHeight)
    color: "transparent"

    Component.onCompleted: {
        console.log("AppLauncher (components) loaded successfully!")

        // Wait for global state to be available
        var connectTimer = Qt.createQmlObject('import QtQuick 2.15; Timer { interval: 100; repeat: true }', appLauncher)
        connectTimer.triggered.connect(function() {
            if (typeof globalThis !== 'undefined' && globalThis.globalAppState) {
                console.log("Connecting to global app state")

                // Connect to the global state changes
                globalThis.globalAppState.globalAppStateChanged.connect(function(processName, active, lastLaunched) {
                    console.log("AppLauncher: Received global state change for", processName, "active:", active)
                    updateLocalAppState(processName, active, lastLaunched)
                })

                // Sync initial states
                syncAllAppStates()

                connectTimer.destroy()
            }
        })
        connectTimer.start()

        // Start the process monitoring timer
        processCheckTimer.start()
    }

    // Function to update local model from global state
    function updateLocalAppState(processName, active, lastLaunched) {
        for (let i = 0; i < appList.model.count; i++) {
            const app = appList.model.get(i)
            if (app.processName === processName) {
                console.log("Updating local state for", processName, "to active:", active)
                appList.model.setProperty(i, "active", active)
                appList.model.setProperty(i, "lastLaunched", lastLaunched)
                break
            }
        }
    }

    // Function to sync all app states on startup
    function syncAllAppStates() {
        for (let i = 0; i < appList.model.count; i++) {
            const app = appList.model.get(i)
            const globalState = AppState.getAppState(app.processName)
            if (globalState.active !== app.active) {
                console.log("Syncing", app.processName, "to global state:", globalState.active)
                appList.model.setProperty(i, "active", globalState.active)
                appList.model.setProperty(i, "lastLaunched", globalState.lastLaunched)
            }
        }
    }

    ListView {
        id: appList
        width: parent.width
        height: parent.height
        orientation: ListView.Vertical
        spacing: 5
        clip: true
        interactive: false

        model: ListModel {
            ListElement {
                name: "Power Menu"
                icon: "🔌"
                command: "qdbus6 org.kde.LogoutPrompt /LogoutPrompt promptAll"
                processName: "qdbus6"
                active: false
                lastLaunched: 0
            }
            ListElement {
                name: "App Drawer"
                icon: "📱"
                command: "nwg-drawer"
                processName: "nwg-drawer"
                active: false
                lastLaunched: 0
            }
            ListElement {
                name: "System Settings"
                icon: "⚙️"
                command: "systemsettings"
                processName: "systemsettings"
                active: false
                lastLaunched: 0
            }
            ListElement {
                name: "Terminal"
                icon: "🖥️"
                command: "konsole"
                processName: "konsole"
                active: false
                lastLaunched: 0
            }
            ListElement {
                name: "Files"
                icon: "📁"
                command: "dolphin"
                processName: "dolphin"
                active: false
                lastLaunched: 0
            }
            ListElement {
                name: "Code Editor"
                icon: "📝"
                command: "code"
                processName: "code"
                active: false
                lastLaunched: 0
            }
            ListElement {
                name: "Zen"
                icon: "🌐"
                command: "zen"
                processName: "zen-bin"
                active: false
                lastLaunched: 0
            }
            ListElement {
                name: "Discord"
                icon: "💬"
                command: "vesktop-bin"
                processName: "vesktop"
                active: false
                lastLaunched: 0
            }
            ListElement {
                name: "Spotify"
                icon: "🎵"
                command: "spotify"
                processName: "spotify"
                active: false
                lastLaunched: 0
            }
            ListElement {
                name: "Writer"
                icon: "📄"
                command: "lowriter"
                processName: "soffice.bin"
                active: false
                lastLaunched: 0
            }
        }

        delegate: Rectangle {
            id: appIcon
            width: 40
            height: 40
            radius: 8

            color: model.active ? Qt.rgba(0.3, 0.6, 1.0, 0.3) : Qt.rgba(1, 1, 1, 0.1)
            border.width: model.active ? 1 : 0
            border.color: Qt.rgba(0.3, 0.6, 1.0, 0.5)

            property bool hovered: false

            Text {
                anchors.centerIn: parent
                text: model.icon
                font.pixelSize: 18
            }

            Rectangle {
                visible: model.active
                width: 3
                height: 6
                radius: 2
                color: "#4facfe"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: -5
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onEntered: {
                    console.log("Mouse entered:", model.name)
                    appIcon.hovered = true
                    var tooltipText = model.name + (model.active ? " (Running)" : " (Click to launch)")
                    console.log("Showing tooltip:", tooltipText)

                    tooltipDelay.tooltipText = tooltipText
                    tooltipDelay.sourceItem = appIcon
                    tooltipDelay.restart()
                }
                onExited: {
                    console.log("Mouse exited:", model.name)
                    appIcon.hovered = false
                    tooltipDelay.stop()
                    customTooltip.hideTooltip()
                }

                onClicked: function(mouse) {
                    console.log("Mouse clicked:", mouse.button, "on", model.name)
                    tooltipDelay.stop()
                    customTooltip.hideTooltip()

                    if (mouse.button === Qt.LeftButton) {
                        if (model.active) {
                            focusApp(model.processName)
                        } else {
                            launchApp(model.command, index)
                        }
                    } else if (mouse.button === Qt.RightButton) {
                        console.log("RIGHT CLICK DETECTED - showing context menu for index:", index)

                        var globalPos = mapToGlobal(mouse.x, mouse.y)
                        console.log("Global mouse position:", globalPos.x, globalPos.y)

                        darkContextMenu.showAt(globalPos.x + 5, globalPos.y - 47, index)

                        console.log("Called showAt for app:", model.name)
                    }
                }

                Timer {
                    id: tooltipDelay
                    interval: 500
                    property string tooltipText: ""
                    property var sourceItem: null

                    onTriggered: {
                        if (parent.containsMouse && sourceItem) {
                            customTooltip.showTooltip(tooltipText, sourceItem)
                        }
                    }
                }
            }
        }
    }

    // Custom dark tooltip - positioned as a top-level item
    Item {
        id: customTooltip
        visible: false
        opacity: 0
        z: 999999
        width: tooltipRect.width
        height: tooltipRect.height

        Rectangle {
            id: tooltipRect
            color: "#1a1a1a"
            border.color: "#404040"
            border.width: 2
            radius: 6
            width: tooltipText.implicitWidth + 16
            height: tooltipText.implicitHeight + 12

            Text {
                id: tooltipText
                anchors.centerIn: parent
                color: "#ffffff"
                font.pixelSize: 12
                font.family: "monospace"
                font.weight: Font.Bold
            }

            // Add a shadow for better visibility
            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                color: "#000000"
                opacity: 0.5
                radius: parent.radius + 1
                z: -1
            }
        }

        function showTooltip(text, sourceItem) {
            console.log("showTooltip called with text:", text)
            tooltipText.text = text

            // Position tooltip to the RIGHT of the app icon, not at cursor
            var itemPos = sourceItem.mapToItem(appLauncher.parent, 0, 0)
            console.log("Source item position relative to parent:", itemPos.x, itemPos.y)

            // Position tooltip to the right of the icon with some padding
            customTooltip.x = itemPos.x + sourceItem.width + 10
            customTooltip.y = itemPos.y + (sourceItem.height - tooltipRect.height) / 2

            console.log("Tooltip positioned at:", customTooltip.x, customTooltip.y)
            console.log("Tooltip size:", tooltipRect.width, "x", tooltipRect.height)

            // Keep tooltip on screen
            if (customTooltip.x < 0) customTooltip.x = 10
                if (customTooltip.y < 0) customTooltip.y = 10

                    visible = true
                    console.log("Tooltip visible set to true, opacity will animate to 0.95")
                    showAnimation.start()
        }

        function hideTooltip() {
            console.log("hideTooltip called")
            hideAnimation.start()
        }

        NumberAnimation {
            id: showAnimation
            target: customTooltip
            property: "opacity"
            to: 0.95
            duration: 200
            onFinished: console.log("Show animation finished, tooltip opacity:", customTooltip.opacity)
        }

        NumberAnimation {
            id: hideAnimation
            target: customTooltip
            property: "opacity"
            to: 0
            duration: 150
            onFinished: {
                console.log("Hide animation finished")
                customTooltip.visible = false
            }
        }
    }

    // Custom dark context menu as a separate window
    Window {
        id: darkContextMenu
        property int appIndex: -1

        width: 180
        height: menuColumn.implicitHeight + 20
        flags: Qt.Popup | Qt.FramelessWindowHint
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#1a1a1a"
            border.color: "#404040"
            border.width: 1
            radius: 6

            Column {
                id: menuColumn
                anchors.centerIn: parent
                width: parent.width - 20
                spacing: 2

                Rectangle {
                    width: parent.width
                    height: 28
                    radius: 4
                    color: closeMouseArea.containsMouse ? "#333333" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Close Application"
                        color: (darkContextMenu.appIndex >= 0 && appList.model.get(darkContextMenu.appIndex).active) ? "#ffffff" : "#666666"
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: closeMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: darkContextMenu.appIndex >= 0 && appList.model.get(darkContextMenu.appIndex).active
                        onClicked: {
                            if (darkContextMenu.appIndex >= 0) {
                                const processName = appList.model.get(darkContextMenu.appIndex).processName
                                appList.model.setProperty(darkContextMenu.appIndex, "active", false)
                                closeApp(processName)
                            }
                            darkContextMenu.visible = false
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#404040"
                }

                Rectangle {
                    width: parent.width
                    height: 28
                    radius: 4
                    color: launchMouseArea.containsMouse ? "#333333" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Launch New Instance"
                        color: "#ffffff"
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: launchMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (darkContextMenu.appIndex >= 0) {
                                launchApp(appList.model.get(darkContextMenu.appIndex).command, darkContextMenu.appIndex)
                            }
                            darkContextMenu.visible = false
                        }
                    }
                }
            }
        }

        // MouseArea to detect clicks outside the menu items
        MouseArea {
            anchors.fill: parent
            z: -1 // Behind the menu items
            onClicked: {
                console.log("Clicked outside menu items - closing menu")
                darkContextMenu.visible = false
            }
        }

        function showAt(globalX, globalY, index) {
            console.log("showAt called with:", globalX, globalY, "index:", index)

            // Always hide first, then immediately show at new position
            visible = false
            appIndex = index
            x = globalX
            y = globalY
            visible = true

            console.log("Context menu repositioned and shown at:", x, y)
        }
    }

    function launchApp(command, index) {
        console.log("Launching on host:", command)

        try {
            let hostCommand;

            // Handle complex commands with arguments by using shell execution
            if (command.includes(" ")) {
                hostCommand = ["distrobox-host-exec", "sh", "-c", command];
            } else {
                hostCommand = ["distrobox-host-exec", command];
            }

            console.log("Executing command:", hostCommand)
            Quickshell.execDetached(hostCommand);

            const processName = appList.model.get(index).processName

            // Update local state immediately
            console.log("Updating local state immediately for", processName)
            appList.model.setProperty(index, "lastLaunched", Date.now())
            appList.model.setProperty(index, "active", true)

            // Update global state if available
            if (typeof globalThis !== 'undefined' && globalThis.globalAppState) {
                console.log("Updating global state for", processName)
                globalThis.globalAppState.updateGlobalState(processName, true, Date.now())
            }

            console.log("Host launch successful!")
        } catch (error) {
            console.log("Host launch failed:", error)
        }
    }

    function focusApp(processName) {
        console.log("Focusing app on KWin Wayland:", processName)
        try {
            const focusCommand = ["distrobox-host-exec", "sh", "-c",
            `qdbus org.kde.KWin /KWin org.kde.KWin.showApplicationWindow "${processName}" 2>/dev/null || ` +
            `echo "Focus attempt completed"`]
            Quickshell.execDetached(focusCommand)
        } catch (error) {
            console.log("Focus failed:", error)
        }
    }

    function closeApp(processName) {
        console.log("Closing app:", processName)
        try {
            const closeCommand = ["distrobox-host-exec", "sh", "-c",
            `pkill -TERM "${processName}" 2>/dev/null; sleep 2; pkill -KILL "${processName}" 2>/dev/null || true`]
            Quickshell.execDetached(closeCommand)

            // Update local state immediately
            for (let i = 0; i < appList.model.count; i++) {
                const app = appList.model.get(i)
                if (app.processName === processName) {
                    console.log("Updating local state immediately for", processName, "to inactive")
                    appList.model.setProperty(i, "active", false)
                    break
                }
            }

            // Update global state if available
            if (typeof globalThis !== 'undefined' && globalThis.globalAppState) {
                console.log("Updating global state for", processName, "to inactive")
                globalThis.globalAppState.updateGlobalState(processName, false, Date.now())
            }

        } catch (error) {
            console.log("Close failed:", error)
        }
    }
}
