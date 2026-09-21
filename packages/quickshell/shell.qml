//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import qs.Modules.Bar
import qs.Modules.Calendar
import qs.Modules.Clipboard
import qs.Modules.ControlCenter
import qs.Modules.Launcher
import qs.Modules.Lock
import qs.Modules.Notifications
import qs.Modules.OSD
import qs.Modules.Session
import qs.Modules.Windows

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

    Clipboard {
        id: clipboard
    }

    WindowSwitcher {
        id: windowSwitcher
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
        target: "clipboard"

        function toggle(): void {
            clipboard.toggle();
        }
    }

    IpcHandler {
        target: "windows"

        function toggle(): void {
            windowSwitcher.toggle();
        }
    }

    IpcHandler {
        target: "controlcenter"

        function toggle(): void {
            controlCenter.toggle();
        }

        function openTab(name: string): void {
            controlCenter.openTab(name);
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
