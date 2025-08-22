//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules"
import "modules/drawers"
import "modules/background"
import "modules/areapicker"
import "modules/lock"
import Quickshell
import "./modules/shared" as Shared

ShellRoot {
    // Move the GlobalAppState inside ShellRoot
    Shared.GlobalAppState {
        id: globalAppState
    }
    
    Background {}
    Drawers {}
    AreaPicker {}
    Lock {}

    Shortcuts {}
}
