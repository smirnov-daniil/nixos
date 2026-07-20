//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import qs.Modules.Bar
import qs.Modules.Calendar
import qs.Modules.ControlCenter
import qs.Modules.Launcher
import qs.Modules.Lock
import qs.Modules.Notifications
import qs.Modules.OSD
import qs.Modules.Session

ShellRoot {
    id: root

    Bar {
        calendar: calendar
        controlCenter: controlCenter
        notificationHistory: history
        sessionMenu: session
    }

    Sound {}
    Brightness {}
    Popups {}
    BatteryAlerts {}

    Launcher {
        id: launcher
    }

    ControlCenter {
        id: controlCenter
    }

    History {
        id: history
    }

    Calendar {
        id: calendar
    }

    LockScreen {
        id: lockScreen
    }

    SessionMenu {
        id: session
        lockScreen: lockScreen
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            launcher.toggle();
        }
    }

    IpcHandler {
        target: "controlcenter"

        function toggle(): void {
            controlCenter.toggle();
        }
    }

    IpcHandler {
        target: "history"

        function toggle(): void {
            history.toggle();
        }
    }

    IpcHandler {
        target: "calendar"

        function toggle(): void {
            calendar.toggle();
        }
    }

    IpcHandler {
        target: "session"

        function toggle(): void {
            session.toggle();
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            lockScreen.lock();
        }
    }
}
