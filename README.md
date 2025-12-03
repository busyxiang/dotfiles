# Dotfiles

Personal configuration files for Linux desktop environments, managed with GNU Stow for easy symlink management.

## Repository Structure

```
dotfiles/
├── minimal_city_pop/     # Hyprland rice with City Pop aesthetic
│   ├── btop/            # System monitor configuration
│   ├── fastfetch/       # System info display
│   ├── hypr/            # Hyprland window manager
│   ├── kitty/           # Terminal emulator
│   ├── lazygit/         # Git TUI
│   ├── mako/            # Notification daemon
│   ├── waybar/          # Status bar
│   └── yazi/            # File manager
└── README.md
```

## Quick Start

### Prerequisites

Install GNU Stow:

```bash
# Arch Linux
sudo pacman -S stow

# Debian/Ubuntu
sudo apt install stow
```

### Installation

1. Clone the repository:

```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

2. Use GNU Stow to create symlinks:

```bash
# Install the minimal_city_pop configuration
stow -t ~/.config minimal_city_pop

# Or install specific components only
stow -t ~/.config/hypr minimal_city_pop/hypr
stow -t ~/.config/kitty minimal_city_pop/kitty
```

3. Remove configurations if needed:

```bash
# Remove all symlinks for minimal_city_pop
stow -D -t ~/.config minimal_city_pop
```

## Configurations

### Minimal City Pop

A cohesive Hyprland dotfiles configuration with a pastel City Pop / Anime Vaporwave aesthetic featuring neon pinks, cyans, purples, and teals.

![Preview](minimal_city_pop/preview.png)

**Included applications:**
- Hyprland (window manager)
- Kitty (terminal)
- Waybar (status bar)
- Mako (notifications)
- Yazi (file manager)
- btop (system monitor)
- Lazygit (git UI)
- fastfetch (system info)

See [minimal_city_pop/README.md](minimal_city_pop/README.md) for detailed documentation.

## Usage with GNU Stow

GNU Stow creates symlinks from your dotfiles repository to your home directory, making it easy to manage configurations across multiple machines.

### Basic Commands

```bash
# Install (create symlinks)
stow -t <target-directory> <package-name>

# Remove (delete symlinks)
stow -D -t <target-directory> <package-name>

# Reinstall (update symlinks)
stow -R -t <target-directory> <package-name>

# Dry run (preview changes)
stow -n -v -t <target-directory> <package-name>
```

### Examples

```bash
# Install everything from minimal_city_pop to ~/.config
cd ~/dotfiles
stow -t ~/.config minimal_city_pop

# Install only Hyprland configs
stow -t ~/.config/hypr minimal_city_pop/hypr

# Preview what would be installed
stow -n -v -t ~/.config minimal_city_pop

# Remove all minimal_city_pop symlinks
stow -D -t ~/.config minimal_city_pop
```

### Directory Structure for Stow

Stow expects a specific directory structure. The contents of each package directory should mirror the target directory structure:

```
dotfiles/
└── minimal_city_pop/
    ├── hypr/
    │   └── hyprland.conf    → will link to ~/.config/hypr/hyprland.conf
    ├── kitty/
    │   └── kitty.conf       → will link to ~/.config/kitty/kitty.conf
    └── ...
```

When you run `stow -t ~/.config minimal_city_pop`, Stow creates:
- `~/.config/hypr/hyprland.conf` → `~/dotfiles/minimal_city_pop/hypr/hyprland.conf`
- `~/.config/kitty/kitty.conf` → `~/dotfiles/minimal_city_pop/kitty/kitty.conf`

## Managing Multiple Machines

For machine-specific configurations, you can:

1. **Use branches:**
```bash
git checkout -b laptop
# Modify configs for laptop
git commit -am "Laptop-specific settings"

git checkout master
git checkout -b desktop
# Modify configs for desktop
```

2. **Use separate packages:**
```
dotfiles/
├── minimal_city_pop/     # Shared configs
├── laptop/               # Laptop-specific
└── desktop/              # Desktop-specific
```

3. **Use environment variables in configs:**
```conf
# In hyprland.conf
monitor=$MONITOR_SETUP
```

## Backup Existing Configs

Before installing, backup your existing configurations:

```bash
# Backup existing configs
mkdir -p ~/config_backup
cp -r ~/.config/hypr ~/config_backup/
cp -r ~/.config/kitty ~/config_backup/
# ... etc

# Or create a timestamped backup
tar -czf ~/config_backup_$(date +%Y%m%d_%H%M%S).tar.gz ~/.config/
```

## Troubleshooting

### Conflicts with Existing Files

If you have existing configuration files, Stow will not overwrite them. You'll see an error like:

```
WARNING! stowing hypr would cause conflicts:
  * existing target is not owned by stow: hypr/hyprland.conf
```

**Solutions:**
1. Backup and remove the existing files
2. Use `--adopt` to replace repository files with existing ones:
   ```bash
   stow --adopt -t ~/.config minimal_city_pop
   git diff  # Review changes
   git checkout .  # Revert if needed
   ```

### Wrong Target Directory

Ensure you're using the correct target directory for each configuration:

```bash
# Most configs go to ~/.config
stow -t ~/.config minimal_city_pop

# Some might go to home directory
stow -t ~ some_package

# Check where symlinks will be created (dry run)
stow -n -v -t ~/.config minimal_city_pop
```

### Broken Symlinks

If you move the dotfiles directory, symlinks will break. Restow to fix:

```bash
cd ~/dotfiles
stow -R -t ~/.config minimal_city_pop
```

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## License

This repository is provided as-is for personal use and modification.
