//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import qs.Modules.Bar
import qs.Modules.ControlCenter
import qs.Modules.Launcher
import qs.Modules.Notifications
import qs.Modules.OSD
import qs.Modules.Session

ShellRoot {
    id: root

    Bar {
        controlCenter: controlCenter
        notificationHistory: history
        sessionMenu: session
    }

    Sound {}
    Brightness {}
    Popups {}

    Launcher {
        id: launcher
    }

    ControlCenter {
        id: controlCenter
    }

    History {
        id: history
    }

    SessionMenu {
        id: session
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
        target: "session"

        function toggle(): void {
            session.toggle();
        }
    }
}
