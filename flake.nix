{
  description = "Bootstrap macOS SSH access using YubiKey PIV via PKCS#11";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        libykcs11 =
          if pkgs.stdenv.isDarwin then
            "${pkgs.yubico-piv-tool}/lib/libykcs11.dylib"
          else
            "${pkgs.yubico-piv-tool}/lib/libykcs11.so";
      in
      {
        formatter = pkgs.nixfmt-rfc-style;

        packages.default = pkgs.writeShellApplication {
          name = "nix-config-bootstrap";

          runtimeInputs = with pkgs; [
            coreutils
            git
            gnused
            jq
            openssh
            yubico-piv-tool
          ];

          text = ''
            set -euo pipefail

            # Start ssh-agent with YubiKey lib path whitelisted
            eval "$(ssh-agent -s -P '${pkgs.yubico-piv-tool}/lib*/*')" || {
              echo "failed to start ssh-agent" >&2
            }

            # Check YubiKey presence and add if detected
            if ${pkgs.yubico-piv-tool}/bin/yubico-piv-tool -a status >/dev/null 2>&1; then
              ssh-add -s ${libykcs11} || echo "failed to add YubiKey" >&2
            fi

            # Add GitHub ED25519 SSH host key
            mkdir -p ~/.ssh
            if ! grep -q '^github.com ssh-ed25519' ~/.ssh/known_hosts 2>/dev/null; then
              echo "adding GitHub ED25519 SSH host key to known_hosts"
              echo 'github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl' >> ~/.ssh/known_hosts
            fi

            # Clone or update nixos-config repository
            mkdir -p ~/src/github.com/lzpreslav
            cd ~/src/github.com/lzpreslav

            if [ ! -d "nix-config" ]; then
              nix flake clone "git+ssh://git@github.com/lzpreslav/nix-config.git" --dest nix-config
              cd nix-config
            else
              echo "nix-config directory exists, pulling latest changes"
              cd nix-config
              git pull
            fi

            if [ "$(uname)" = "Darwin" ]; then
              cd  ~/src/github.com/lzpreslav/nix-config

              read -p "hostname for darwin-rebuild: " -r hostname

              if [ -z "$hostname" ]; then
                echo "no hostname entered, aborting" >&2
                exit 1
              fi

              echo "switching to: $hostname"
              nix run nix-darwin/master#darwin-rebuild -- switch --flake ".#$hostname"
            else
              echo "not on macOS, skipping darwin-rebuild"
            fi
          '';
        };
      }
    );
}
