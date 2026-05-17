# Modular NixOS Configuration

This repository contains a comprehensive, modular NixOS configuration managed via Nix Flakes. It is designed to provide a consistent yet flexible environment across multiple hardware targets, incorporating a wide array of modern tools and an integrated AI coding assistant.

## 🚀 Core Architecture

The project utilizes a modern Nix stack for maximum reproducibility and maintainability:

- **Nix Flakes**: The primary mechanism for dependency management and system reproducibility.
- **`flake-parts`**: Used to structure the flake outputs and imports cleanly.
- **`import-tree`**: Automates the discovery and import of Nix modules, reducing the need for manual import lists.
- **`sops-nix`**: Handles encrypted secrets management, ensuring sensitive data is not stored in plaintext.
- **`nh`**: Used for streamlined system management and switching.

## 📁 Project Structure

The configuration is split into three main areas:

### 1. Hosts (`/hosts`)
Contains machine-specific configurations. Each host folder (e.g., `aku`, `gru`, `lich`) contains:
- `default.nix`: The host's entry point.
- `configuration.nix`: Host-specific system settings.
- `hardware.nix`: Generated hardware configuration.

### 2. NixOS Modules (`/nixos`)
Shared logic divided into:
- **`base/`**: Fundamental system settings such as user accounts, keymaps, and monitor configurations.
- **`features/`**: Modular "opt-in" components. These include networking, desktop environments, hardware-specific optimizations (e.g., Intel), and the AI agent integration.

### 3. Packages (`/packages`)
Custom package definitions and application-specific configurations:
- **Environment**: Core toolsets (`git`, `zsh`, `helix`).
- **UI/UX**: Modern tooling like `ghostty` (terminal), `niri` (tiling compositor), and `zen-browser`.
- **QuickShell**: A custom-built shell and OSD (On-Screen Display) implemented in QML, providing a tailored status bar and system widgets.

## 🤖 AI Agent Integration (`pi`)

This project integrates [pi](https://github.com/earendil-works/pi), an AI coding agent, directly into the system configuration.

Located in `nixos/features/pi/`, the integration includes:
- **Module**: `default.nix` handles the agent's installation and system-level configuration.
- **Models**: `models.json` manages the AI models used by the agent.
- **Extensions**: Custom TypeScript extensions (e.g., `prefer-rg.ts`) extend the agent's native capabilities within this specific environment.

## 🛠️ Management Workflow

### Applying Changes
The project prefers the use of `nh` for applying configurations:
```bash
sudo nh os switch
```

### Updating Dependencies
To update all flake inputs (nixpkgs, etc.):
```bash
nix flake update
```

### Adding New Features
1. Create a new `.nix` file in `nixos/features/`.
2. Include the module in the `configuration.nix` of the desired host.
3. Rebuild the system.
