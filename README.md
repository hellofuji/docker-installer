# Docker Installation Script for Linux

[![Linux](https://img.shields.io/badge/Linux-Tux-informational?style=flat&logo=linux&logoColor=white)](https://www.linux.org)
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Open Source](https://badges.frapsoft.com/os/v1/open-source.svg?v=103)](https://opensource.org)

A production-ready script to install Docker and Docker Compose across all major Linux distributions with intelligent OS detection and hardened security configuration.

## Tested Distributions

[![Raspberry Pi](https://img.shields.io/badge/-Raspberry%20Pi%20OS-C51A4A?logo=raspberrypi)](https://www.raspberrypi.com/software/)
[![Ubuntu](https://img.shields.io/badge/-Ubuntu-E95420?logo=ubuntu)](https://ubuntu.com)
[![Fedora](https://img.shields.io/badge/-Fedora-294172?logo=fedora)](https://fedoraproject.org)
[![Arch](https://img.shields.io/badge/-Arch%20Linux-1793D1?logo=archlinux)](https://archlinux.org)
[![Debian](https://img.shields.io/badge/-Debian-A81D33?logo=debian)](https://www.debian.org)

## Features
- 🐧 Universal Support: Works on Debian, Ubuntu, RHEL, CentOS, Fedora, Arch Linux, and derivatives
- 🔍 Smart Detection: Automatically identifies your distribution and package manager
- 🛡️ Safe Installation: Follows official Docker installation guidelines
- 🚦 Error Handling: Clear color-coded messages for success/warning/error states
- 🛠️ Post-Install Setup: Configures Docker service and user permissions

## Supported Systems

| Distribution Family | Package Manager | Verified Versions |
|---------------------|-----------------|-------------------|
| Debian/Ubuntu       | `apt`           | Ubuntu 20.04+, Debian 10+ |
| RHEL/CentOS         | `dnf`/`yum`     | RHEL 8+, CentOS 7+ |
| Fedora              | `dnf`           | Fedora 36+ |
| Arch Linux          | `pacman`        | Rolling release |
| SUSE                | `zypper`        | openSUSE Leap 15+ |

## Prerequisites
- Linux system (tested on most major distributions)
- Internet connection
- sudo privileges

## Installation
Download and execute the installer
```bash
curl -fsSL https://raw.githubusercontent.com/hellofuji/docker-installer/main/install_docker.sh | bash
```

## What the Script Does
- Detects your Linux distribution and package manager
- Adds the official Docker repository for your distro
- Imports Docker's GPG key
- Installs Docker Engine, CLI, Containerd, and Docker Compose
- Starts and enables the Docker service
- Adds your user to the docker group

## Post-Installation

After successful installation:

- Log out and back in for group changes to take effect
- Verify with: `docker run hello-world`

## Troubleshooting

If you encounter issues:

- Check error messages (red text)
- Verify your internet connection
- Ensure you have sudo privileges
- Consult Docker's official documentation for your distribution

## Security Note
This script:
- Only uses official Docker repositories
- Verifies package signatures
- Doesn't persist any sensitive data

**⚠️ Always review scripts before running them with sudo privileges.**

