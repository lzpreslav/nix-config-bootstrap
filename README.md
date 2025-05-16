# Nix Config Bootstrap

Supports using YubiKey PIV for cloning my private nix-config repo

## Initial setup of MacBook

### Prerequisites

- Install Nix via [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer). Make sure to **select NO** when asked about whether to install Determinate Nix.

   ```sh
   curl -fsSL -o nix-installer https://github.com/DeterminateSystems/nix-installer/releases/download/v3.5.2/nix-installer-aarch64-darwin
   chmod +x nix-installer
   ./nix-installer install
   ```

- Install Command Line Tools

    ```sh
    xcode-select --install
    ```

- Log in Apple ID/App Store to allow using MAS to download apps from the store

### Setup

1. Plug in YubiKey
2. Run this flake

    ```sh
    nix run github:lzpreslav/nix-config-bootstrap
    ```

3. Type the name of the darwinConfiguration when asked

### After initial setup

Reboot, then open the graphical apps one by one to allow macOS to launch them (Raycast, Rectangle, Snap, etc.). Please note that some of them also require allowing some accessibility/security features from System Settings.
