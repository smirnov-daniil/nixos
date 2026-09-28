---
name: fix-niri-greetd-prime-session
description: Diagnose Niri/greetd boot and hybrid-GPU GL failures on NixOS without conflating display-manager, compositor, shell, and client failures.
---

Treat plain TTY, failed Niri, missing QuickShell, and client EGL failures as separate layers. Do not change GPU selection or greetd TTY handling without target-host logs.

1. From the failed boot, capture `systemctl status greetd.service display-manager.service graphical.target --no-pager -l`, `systemctl get-default`, `systemctl is-enabled greetd.service`, `systemctl cat greetd.service`, and `journalctl -b -u greetd.service --no-pager -n 200`. If greetd is absent, investigate the selected boot generation; if failed, use its stable status and journal error; if active but invisible, then inspect VT ownership.
2. Recover first with the bootloader's previous generation or `sudo nixos-rebuild switch --rollback`, preserving logs before reboot.
3. Missing QuickShell is downstream of Niri not running; inspect it only after the compositor starts.
4. Capture target GPU topology with `lspci -Dnnk -d ::03xx` and `/dev/dri/by-path` before pinning any render node. Never assume a by-path name from PRIME bus IDs alone.
5. Once `niri-session` is running, inspect `systemctl --user show-environment`, `journalctl --user -b -u niri.service`, the exact Ghostty wrapper path/version, and run Ghostty via `systemd-run --user --wait --pipe --collect` to preserve its EGL error. Compare default and offloaded `eglinfo -B`/renderer diagnostics.
6. A cleanup wrapper used only by greetd does not cover manual or desktop-entry `niri-session` launches. If environment cleanup is proven necessary, place it in the common session entrypoint and fail visibly if cleanup cannot be applied.
7. Validate statically with `nix flake check`, generated service/config inspection, and `niri validate`, but state clearly that these cannot establish target-host VT or EGL behavior.
