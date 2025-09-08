# Dotfiles

A dotfiles management system using Chezmoi for orchestration and best-in-class tools (aqua, mise, homebrew) for package management.

## Overview

This dotfiles repository provides a way for managing my development environment across multiple machines with a focus on:

- **Lightweight operation**: Everything runs on-demand, no background daemons
- **Modular design**: Clean separation of concerns with specialized tools
- **Cross-platform compatibility**: Works on macOS and Linux with OS-specific settings
- **Reproducibility**: Version-controlled configurations

## Core Components

### Chezmoi: The Orchestrator

[Chezmoi](https://www.chezmoi.io/) serves as the central orchestrator for the entire dotfiles ecosystem:

- Manages configuration files with templating support
- Runs scripts in a controlled, ordered manner
- Handles machine-specific differences
- Provides a consistent way to update configurations

### Tool Management

The repository integrates several specialized tools:

- **[Aqua](https://aquaproj.github.io/)**: Manages CLI binaries (kubectl, helm, etc.)
  - Speedy, lightweight, reproducible installation
  - Version-controlled binary management
  - Packages: [.config/aquaproj-aqua/aqua.yaml](private_dot_config/aquaproj-aqua/aqua.yaml)

- **[Mise](https://mise.jdx.dev/)**: Manages language SDKs and runtimes
  - Handles multiple versions of languages (Rust, Go, Node, Python, etc.)
  - Manages global tool installations via pipx, npm, etc.
  - Packages: [.config/mise/config.toml](private_dot_config/mise/config.toml)

- **[Homebrew](https://brew.sh/)**: Manages system packages (Linux/MacOS) and GUI apps (macOS)
  - Uses Brewfile for reproducible installations
  - Handles GUI applications via Casks
  - Packages:
    - System: [MacOS](Brewfile.system.darwin) | [Linux](Brewfile.system.linux)
    - Docker: [Brewfile.docker](Brewfile.docker)
    - GUI: [Brewfile.gui](Brewfile.gui)

- **[Krew](https://krew.sigs.k8s.io/)**: Manages kubectl plugins (ctx, ns, stern, etc.)
  - Uses a simple text file listing required plugins
  - Packages: [krew-plugins.txt](krew-plugins.txt)

## Getting Started

### Initial Setup

Install Chezmoi and initialize with this repository:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply ppat/dotfiles
```

Chezmoi will:

- Install required tools (Homebrew, Aqua, Mise)
- Set up environment files
- Configure your shell and environment

### Ongoing updates

To update system/environment with latest version from git,

```bash
chezmoi update
```

Chezmoi will:

- Fetch latest from git
- Apply all the updates
