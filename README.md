# NixOS Configuration

A comprehensive NixOS flake configuration for Framework 13 laptop with AMD Ryzen 7040U series processor.

## 🖥️ System Overview

This configuration provides a complete NixOS setup optimized for the Framework 13 laptop, including:
- Desktop environment configuration
- Power management optimizations for laptop use
- Gaming support
- Virtualization capabilities
- VPN setup
- Custom application configurations
- Flatpak integration

## 📋 Prerequisites

- NixOS installed on your system
- Flakes enabled in your Nix configuration
- Git installed for cloning the repository

To enable flakes, add the following to your `/etc/nixos/configuration.nix`:
```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

## 🚀 Installation

1. Clone this repository:
```bash
git clone https://github.com/artur9010/nixos.git
cd nixos
```

2. Review and customize the configuration files according to your needs.

3. Apply the configuration:
```bash
sudo nixos-rebuild switch --flake .#ramapraca --show-trace
```

## 📁 Repository Structure

```
.
├── configuration.nix          # Main system configuration
├── hardware-configuration.nix # Hardware-specific settings (auto-generated)
├── flake.nix                 # Flake definition with inputs and outputs
├── flake.lock                # Lock file for reproducible builds
├── system/                   # Modular system configurations
│   ├── desktop.nix          # Desktop environment setup
│   ├── powermanagement.nix  # Power management and battery optimization
│   ├── shell.nix            # Shell configuration
│   ├── vpn.nix              # VPN configuration
│   ├── gaming.nix           # Gaming-related packages and setup
│   ├── virtualization.nix   # VM and container support
│   ├── flatpak.nix          # Flatpak integration
│   ├── locale.nix           # Locale and internationalization
│   ├── apple-fonts.nix      # Apple fonts configuration
│   └── apps/                # Application-specific configurations
│       └── ledger-live.nix  # Ledger hardware wallet app
├── pkgs/                     # Custom package definitions
└── assets/                   # Assets and resources
```

## 🔧 System Modules

### Desktop Environment
Configured in `system/desktop.nix` - includes window manager, display manager, and desktop applications.

### Power Management
Configured in `system/powermanagement.nix` - optimizes battery life and thermal management for the Framework laptop.

### Gaming
Configured in `system/gaming.nix` - includes Steam, game compatibility layers, and gaming-related tools.

### Virtualization
Configured in `system/virtualization.nix` - supports QEMU/KVM and container technologies.

### VPN
Configured in `system/vpn.nix` - VPN client setup and configuration.

### Flatpak
Configured in `system/flatpak.nix` - integrates Flatpak for additional application sources.

## 🎯 Customization

### Changing the Hostname
The system hostname is set in `configuration.nix`:
```nix
networking.hostName = "ramapraca";
```

### Adding New Packages
Add packages to the `environment.systemPackages` list in `configuration.nix` or create a new module in the `system/` directory.

### Modifying Boot Configuration
Boot settings including kernel version and bootloader options are configured in `configuration.nix`.

## 🔄 Updating the System

To update all flake inputs to their latest versions:
```bash
nix flake update
```

Then rebuild the system:
```bash
sudo nixos-rebuild switch --flake .#ramapraca --show-trace
```

## 🐛 Troubleshooting

### Show detailed error messages
The `--show-trace` flag provides detailed error traces during rebuild.

### Rollback to previous generation
If something goes wrong:
```bash
sudo nixos-rebuild switch --rollback
```

### Check system generations
```bash
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

## 📝 TODOs

- [ ] Replace Floorp Flatpak with Floorp Nix package ([reference](https://noogle.dev/f/pkgs/wrapFirefox))
- [ ] Add EufyMake Studio configuration

## 🔗 Flake Inputs

- **nixpkgs**: NixOS unstable channel
- **nixos-hardware**: Hardware-specific configurations (Framework 13 AMD 7040 support)
- **apple-fonts**: Apple San Francisco fonts
- **nix-flatpak**: Declarative Flatpak management

## 📄 License

Personal configuration - use at your own discretion.

## 🤝 Contributing

This is a personal configuration repository, but feel free to fork and adapt it for your own use.