import QtQuick 2.15

Item {
    id: globalState
    
    // Make this a global property accessible from anywhere
    property var globalAppStates: ({})
    
    // Global signal dispatcher
    signal globalAppStateChanged(string processName, bool active, int lastLaunched)
    
    Component.onCompleted: {
        console.log("GlobalAppState created")
        // Make this globally accessible
        if (typeof globalThis === 'undefined') {
            globalThis = {}
        }
        globalThis.globalAppState = globalState
    }
    
    function updateGlobalState(processName, active, lastLaunched) {
        console.log("GlobalAppState: Updating", processName, "active:", active)
        
        // Update the shared state
        globalAppStates[processName] = {
            active: active,
            lastLaunched: lastLaunched || Date.now()
        }
        
        console.log("GlobalAppState: Emitting signal for", processName)
        // Notify all monitors
        globalAppStateChanged(processName, active, lastLaunched)
    }
    
    function getGlobalState(processName) {
        return globalAppStates[processName] || { active: false, lastLaunched: 0 }
    }
}