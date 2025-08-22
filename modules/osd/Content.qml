import qs.components.controls
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick

Column {
    id: root
    required property Brightness.Monitor monitor
    padding: Appearance.padding.large
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    spacing: Appearance.spacing.normal

    // Output Volume Control
    CustomMouseArea {
        implicitWidth: Config.osd.sizes.sliderWidth
        implicitHeight: Config.osd.sizes.sliderHeight
        onWheel: event => {
            if (event.angleDelta.y > 0)
                Audio.incrementVolume();
            else if (event.angleDelta.y < 0)
                Audio.decrementVolume();
        }
        FilledSlider {
            anchors.fill: parent
            icon: Icons.getVolumeIcon(value, Audio.muted)
            value: Audio.volume
            onMoved: Audio.setVolume(value)
        }
    }

    // Input Volume Control (Microphone)
    CustomMouseArea {
        implicitWidth: Config.osd.sizes.sliderWidth
        implicitHeight: Config.osd.sizes.sliderHeight
        onWheel: event => {
            if (event.angleDelta.y > 0) {
                Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_SOURCE@", "5%+"]);
            } else if (event.angleDelta.y < 0) {
                Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_SOURCE@", "5%-"]);
            }
        }
        FilledSlider {
            anchors.fill: parent
            icon: Icons.getVolumeIcon(value, Audio.source?.muted ?? false)
            value: Audio.source?.volume ?? 0
            onMoved: {
                const volumePercent = Math.round(value * 100);
                Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_SOURCE@", `${volumePercent}%`]);
            }
        }
    }

    // Brightness Control (KWin Compatible via Distrobox)
    CustomMouseArea {
        implicitWidth: Config.osd.sizes.sliderWidth
        implicitHeight: Config.osd.sizes.sliderHeight
        onWheel: event => {
            if (event.angleDelta.y > 0) {
                // Increase brightness by ~5% of range (475 units)
                const currentBrightness = Math.round((root.monitor?.brightness ?? 0) * 9500) + 500;
                const newBrightness = Math.min(10000, currentBrightness + 475);
                Quickshell.execDetached(["distrobox-host-exec", "qdbus6", "org.kde.Solid.PowerManagement", "/org/kde/Solid/PowerManagement/Actions/BrightnessControl", "setBrightness", newBrightness.toString()]);
            } else if (event.angleDelta.y < 0) {
                // Decrease brightness by ~5% of range (475 units)
                const currentBrightness = Math.round((root.monitor?.brightness ?? 0) * 9500) + 500;
                const newBrightness = Math.max(500, currentBrightness - 475);
                Quickshell.execDetached(["distrobox-host-exec", "qdbus6", "org.kde.Solid.PowerManagement", "/org/kde/Solid/PowerManagement/Actions/BrightnessControl", "setBrightness", newBrightness.toString()]);
            }
        }
        FilledSlider {
            anchors.fill: parent
            icon: `brightness_${(Math.round(value * 6) + 1)}`
            value: root.monitor?.brightness ?? 0
            onMoved: {
                // Convert 0-1 slider value to 500-10000 range
                const brightnessValue = Math.round(value * 9500) + 500;
                Quickshell.execDetached(["distrobox-host-exec", "qdbus6", "org.kde.Solid.PowerManagement", "/org/kde/Solid/PowerManagement/Actions/BrightnessControl", "setBrightness", brightnessValue.toString()]);
            }
        }
    }
}
