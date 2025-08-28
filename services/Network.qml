pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property list<AccessPoint> networks: []
    readonly property AccessPoint active: networks.find(n => n.active) ?? null
    property bool wifiEnabled: true
    readonly property bool scanning: rescanProc.running

    reloadableId: "network"

    function enableWifi(enabled: bool): void {
        const cmd = enabled ? "on" : "off";
        enableWifiProc.exec(["distrobox-host-exec", "sh", "-c", `nmcli radio wifi ${cmd}`]);
    }

    function toggleWifi(): void {
        const cmd = wifiEnabled ? "off" : "on";
        enableWifiProc.exec(["distrobox-host-exec", "sh", "-c", `nmcli radio wifi ${cmd}`]);
    }

    function rescanWifi(): void {
        rescanProc.running = true;
    }

    function connectToNetwork(ssid: string, password: string): void {
        if (password && password.length > 0) {
            connectProc.exec(["distrobox-host-exec", "sh", "-c", `nmcli device wifi connect "${ssid}" password "${password}"`]);
        } else {
            // For open networks or already known networks
            connectProc.exec(["distrobox-host-exec", "sh", "-c", `nmcli device wifi connect "${ssid}"`]);
        }
    }

    function disconnectFromNetwork(): void {
        if (active) {
            disconnectProc.exec(["distrobox-host-exec", "sh", "-c", `nmcli connection down "${active.ssid}"`]);
        }
    }

    function getWifiStatus(): void {
        wifiStatusProc.running = true;
    }

    Process {
        running: true
        command: ["distrobox-host-exec", "sh", "-c", "nmcli monitor"]
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
    }

    Process {
        id: wifiStatusProc

        running: true
        command: ["distrobox-host-exec", "sh", "-c", "nmcli radio wifi"]
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
            }
        }
    }

    Process {
        id: enableWifiProc

        onExited: {
            root.getWifiStatus();
            getNetworks.running = true;
        }
    }

    Process {
        id: rescanProc

        command: ["distrobox-host-exec", "sh", "-c", "nmcli device wifi list --rescan yes"]
        onExited: {
            getNetworks.running = true;
        }
    }

    Process {
        id: connectProc

        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
        stderr: StdioCollector {
            onStreamFinished: console.warn("Network connection error:", text)
        }
    }

    Process {
        id: disconnectProc

        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
    }

    Process {
        id: getNetworks

        running: true
        command: ["distrobox-host-exec", "sh", "-c", "nmcli -t -f ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY device wifi"]
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const rep = new RegExp("\\\\:", "g");
                const rep2 = new RegExp(PLACEHOLDER, "g");

                const allNetworks = text.trim().split("\n").map(n => {
                    const net = n.replace(rep, PLACEHOLDER).split(":");
                    return {
                        active: net[0] === "yes",
                        strength: parseInt(net[1]),
                                                                frequency: parseInt(net[2]),
                                                                ssid: net[3],
                                                                bssid: net[4]?.replace(rep2, ":") ?? "",
                                                                security: net[5] || ""
                    };
                }).filter(n => n.ssid && n.ssid.length > 0);

                // Group networks by SSID and prioritize connected ones
                const networkMap = new Map();
                for (const network of allNetworks) {
                    const existing = networkMap.get(network.ssid);
                    if (!existing) {
                        networkMap.set(network.ssid, network);
                    } else {
                        // Prioritize active/connected networks
                        if (network.active && !existing.active) {
                            networkMap.set(network.ssid, network);
                        } else if (!network.active && !existing.active) {
                            // If both are inactive, keep the one with better signal
                            if (network.strength > existing.strength) {
                                networkMap.set(network.ssid, network);
                            }
                        }
                        // If existing is active and new is not, keep existing
                    }
                }

                const networks = Array.from(networkMap.values());

                const rNetworks = root.networks;

                const destroyed = rNetworks.filter(rn => !networks.find(n => n.frequency === rn.frequency && n.ssid === rn.ssid && n.bssid === rn.bssid));
                for (const network of destroyed)
                    rNetworks.splice(rNetworks.indexOf(network), 1).forEach(n => n.destroy());

                for (const network of networks) {
                    const match = rNetworks.find(n => n.frequency === network.frequency && n.ssid === network.ssid && n.bssid === network.bssid);
                    if (match) {
                        match.lastIpcObject = network;
                    } else {
                        rNetworks.push(apComp.createObject(root, {
                            lastIpcObject: network
                        }));
                    }
                }
            }
        }
    }

    component AccessPoint: QtObject {
        required property var lastIpcObject
        readonly property string ssid: lastIpcObject.ssid
        readonly property string bssid: lastIpcObject.bssid
        readonly property int strength: lastIpcObject.strength
        readonly property int frequency: lastIpcObject.frequency
        readonly property bool active: lastIpcObject.active
        readonly property string security: lastIpcObject.security
        readonly property bool isSecure: security.length > 0
    }

    Component {
        id: apComp

        AccessPoint {}
    }
}
