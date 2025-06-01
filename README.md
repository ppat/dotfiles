# Dotfiles

A modern, lightweight, and modular dotfiles management system using Chezmoi for orchestration and best-in-class tools (aqua, mise, homebrew) for package management.

## Overview

This dotfiles repository provides a comprehensive solution for managing my development environment across multiple machines with a focus on:

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

- **[Mise](https://mise.jdx.dev/)**: Manages language SDKs and runtimes
  - Handles multiple versions of languages (Rust, Go, Node, Python, etc.)
  - Manages global tool installations via pipx, npm, etc.

- **[Homebrew](https://brew.sh/)**: Manages system packages and GUI apps (macOS)
  - Uses Brewfile for reproducible installations
  - Handles GUI applications via Casks

## Getting Started

### Initial Setup

1. Install Chezmoi and initialize with this repository:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply ppat/dotfiles
```

2. Chezmoi will:
   - Install required tools (Homebrew, Aqua, Mise)
   - Set up environment files
   - Configure your shell and environment

### Manual Installation

If you prefer to set up step-by-step:

1. Clone the repository:

   ```bash
   git clone https://github.com/ppat/dotfiles.git
   cd dotfiles
   ```

2. Install Chezmoi:

   ```bash
   sh -c "$(curl -fsLS get.chezmoi.io)"
   ```

3. Initialize Chezmoi with the local repository:

   ```bash
   chezmoi init --source=.
   chezmoi apply
   ```
