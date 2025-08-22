pragma Singleton
import QtQuick 2.15

QtObject {
    id: globalAppState
    
    // Shared app states - this will be synced across all monitors
    property var appStates: ({})
    
    // Signal to notify all monitors when app state changes
    signal appStateChanged(string processName, bool active, int lastLaunched)
    
    Component.onCompleted: {
        console.log("Global AppState singleton created")
    }
    
    function updateAppState(processName, active, lastLaunched) {
        console.log("GlobalAppState: Updating", processName, "active:", active)
        
        // Update the shared state
        var newStates = appStates
        newStates[processName] = {
            active: active,
            lastLaunched: lastLaunched || Date.now()
        }
        appStates = newStates
        
        console.log("GlobalAppState: Emitting signal for", processName)
        // Notify all monitors
        appStateChanged(processName, active, lastLaunched)
    }
    
    function getAppState(processName) {
        return appStates[processName] || { active: false, lastLaunched: 0 }
    }
    
    function setAppActive(processName) {
        updateAppState(processName, true, Date.now())
    }
    
    function setAppInactive(processName) {
        updateAppState(processName, false, Date.now())
    }
}