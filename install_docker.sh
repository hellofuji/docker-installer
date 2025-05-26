#!/bin/bash

# Docker installation script for multiple Linux distributions
BLUE='\033[0;34m'
echo -e "${BLUE}"
cat <<'EOF'
           ##         .
      ## ## ##        ==
   ## ## ## ## ##    ===
/""""""""""""""""\___/ ===
{       Docker          }
\______  _____________/
       \/
EOF

echo -e "\n🐧 Docker Installation Script 🐧\n"

# Function to print error messages
error_msg() {
    echo -e "\033[1;31m[ERROR] $1\033[0m" >&2
    exit 1
}

# Function to print success messages
success_msg() {
    echo -e "\033[1;32m[SUCCESS] $1\033[0m"
}

# Function to print info messages
info_msg() {
    echo -e "\033[1;34m[INFO] $1\033[0m"
}

# Function to print warning messages
warning_msg() {
    echo -e "\033[1;33m[WARNING] $1\033[0m"
}

# Function to detect architecture
detect_architecture() {
    info_msg "Detecting system architecture..."
    ARCH=$(uname -m)
    case $ARCH in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="armv7"
            ;;
        *)
            warning_msg "Architecture $ARCH may not be fully supported"
            ;;
    esac
    info_msg "Detected architecture: $ARCH"
}

# Function to check system requirements
check_requirements() {
    info_msg "Checking system requirements..."
    
    # Check minimum memory (4GB recommended)
    total_mem=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$total_mem" -lt 4000 ]; then
        warning_msg "Less than 4GB RAM detected ($total_mem MB). Docker may run slowly."
    fi
    
    # Check available disk space (20GB recommended)
    free_space=$(df -BG /var | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$free_space" -lt 20 ]; then
        warning_msg "Less than 20GB free space detected ($free_space GB). This might be insufficient."
    fi
}

# Function to check network connectivity
check_network() {
    info_msg "Checking network connectivity..."
    if ! curl -s --connect-timeout 5 https://download.docker.com > /dev/null; then
        error_msg "No network connectivity to Docker repositories"
    fi
}

# Function to backup existing Docker configs
backup_existing_config() {
    if [ -d "/etc/docker" ]; then
        backup_dir="/etc/docker.backup-$(date +%Y%m%d%H%M%S)"
        info_msg "Creating backup of existing Docker configuration to $backup_dir"
        sudo cp -r /etc/docker "$backup_dir"
    fi
}

# Function to verify Docker installation
verify_installation() {
    info_msg "Verifying Docker installation..."
    if command -v docker >/dev/null 2>&1; then
        version=$(docker --version)
        success_msg "Docker installed successfully: $version"
        if command -v docker-compose >/dev/null 2>&1; then
            compose_version=$(docker compose version)
            success_msg "Docker Compose installed successfully: $compose_version"
        fi
    else
        error_msg "Docker installation verification failed"
    fi
}

# Cleanup function
cleanup() {
    if [ $? -ne 0 ]; then
        warning_msg "Installation failed, cleaning up..."
        case $PKG_MANAGER in
            apt)
                sudo rm -f /etc/apt/keyrings/docker.asc
                sudo rm -f /etc/apt/sources.list.d/docker.list
                ;;
            dnf|yum)
                sudo rm -f /etc/yum.repos.d/docker-ce.repo
                ;;
            zypper)
                sudo zypper removerepo docker-ce
                ;;
        esac
    fi
}

# Set up cleanup trap
trap cleanup EXIT

# Function to detect OS and package manager
detect_os() {
    # First try to detect using /etc/os-release
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
        VERSION=$VERSION_ID
        CODENAME=$VERSION_CODENAME
        
        # Handle special cases for Ubuntu derivatives
        if [ -z "$CODENAME" ] && [ "$OS" = "ubuntu" ]; then
            CODENAME=$UBUNTU_CODENAME
        fi
    # Check for Arch Linux
    elif [ -f /etc/arch-release ]; then
        OS="arch"
        VERSION="rolling"
    # Check for RedHat/CentOS
    elif [ -f /etc/redhat-release ]; then
        OS=$(awk '{print tolower($1)}' /etc/redhat-release)
        VERSION=$(grep -oE '[0-9]+\.[0-9]+' /etc/redhat-release)
    # Check for older Debian
    elif [ -f /etc/debian_version ]; then
        OS="debian"
        VERSION=$(cat /etc/debian_version)
    else
        error_msg "Could not detect OS type."
    fi

    # Handle Linux Mint special case
    if [ "$OS" = "linuxmint" ]; then
        if grep -q "LMDE" /etc/os-release; then
            # Linux Mint Debian Edition
            OS="debian"
            # Get Debian version from /etc/debian_version
            if [ -f "/etc/debian_version" ]; then
                DEBIAN_VERSION=$(cat /etc/debian_version)
                case $DEBIAN_VERSION in
                    *"12"*) CODENAME="bookworm" ;;
                    *"11"*) CODENAME="bullseye" ;;
                    *) CODENAME=$(grep -oP 'DEBIAN_CODENAME=\K.*' /etc/os-release || echo "bookworm") ;;
                esac
            fi
        else
            # Regular Linux Mint (Ubuntu-based)
            OS="ubuntu"
            # Try to get Ubuntu base version directly
            UBUNTU_CODENAME=$(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2)
            if [ -n "$UBUNTU_CODENAME" ]; then
                CODENAME=$UBUNTU_CODENAME
            else
                # Fallback to deriving from Ubuntu version
                UBUNTU_VER=$(grep UBUNTU_VERSION_ID /etc/os-release | cut -d= -f2 | tr -d '"')
                case $UBUNTU_VER in
                    "24.04") CODENAME="noble" ;;
                    "22.04") CODENAME="jammy" ;;
                    "20.04") CODENAME="focal" ;;
                    *) CODENAME=$(lsb_release -cs 2>/dev/null || echo "jammy") ;;
                esac
            fi
        fi
    fi

    # Handle derivative distributions
    case $OS in
        # Ubuntu-based distributions
        pop|elementary|neon|zorin|kubuntu|xubuntu|lubuntu|ubuntu)
            OS="ubuntu"
            # Try multiple methods to get the Ubuntu codename
            if [ -z "$CODENAME" ]; then
                CODENAME=$(lsb_release -cs 2>/dev/null || \
                          grep UBUNTU_CODENAME /etc/os-release 2>/dev/null | cut -d= -f2 || \
                          grep VERSION_CODENAME /etc/os-release 2>/dev/null | cut -d= -f2)
            fi
            ;;
        
        # Debian-based distributions
        kali|deepin|mx|pureos|devuan|parrot|raspbian)
            OS="debian"
            # Get Debian codename dynamically
            if [ -f "/etc/debian_version" ]; then
                # Try to get codename directly from OS
                CODENAME=$(grep VERSION_CODENAME /etc/os-release 2>/dev/null | cut -d= -f2)
                if [ -z "$CODENAME" ]; then
                    # Fallback to version number mapping
                    DEBIAN_VERSION=$(cat /etc/debian_version)
                    case $DEBIAN_VERSION in
                        *"12"*) CODENAME="bookworm" ;;
                        *"11"*) CODENAME="bullseye" ;;
                        *"10"*) CODENAME="buster" ;;
                        *) CODENAME=$(lsb_release -cs 2>/dev/null || echo "bookworm") ;;
                    esac
                fi
            fi
            ;;
        
        # RHEL-based distributions
        centos|rhel|rocky|almalinux|ol|fedora)
            if [ "$OS" = "fedora" ]; then
                OS="fedora"
            else
                OS="centos"  # Treat all RHEL clones as CentOS
            fi
            ;;
        
        # Arch-based distributions
        manjaro|endeavouros|garuda|artix|archcraft)
            OS="arch"
            VERSION="rolling"
            ;;
        
        # openSUSE variations
        opensuse-leap|opensuse-tumbleweed|opensuse*)
            OS="opensuse"
            ;;
        
        *)
            # Last resort OS detection
            if [ -f "/etc/debian_version" ]; then
                OS="debian"
                CODENAME="bookworm"
            elif [ -f "/etc/arch-release" ]; then
                OS="arch"
                VERSION="rolling"
            else
                warning_msg "Unrecognized OS: $OS. Attempting to continue with best guess..."
            fi
            ;;
    esac

    # Detect package manager
    if command -v apt-get >/dev/null 2>&1; then
        PKG_MANAGER="apt"
        info_msg "Detected Debian/Ubuntu system"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
        info_msg "Detected Fedora/RHEL system (dnf)"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
        info_msg "Detected RHEL/CentOS system (yum)"
    elif command -v pacman >/dev/null 2>&1; then
        PKG_MANAGER="pacman"
        info_msg "Detected Arch Linux system"
    elif command -v zypper >/dev/null 2>&1; then
        PKG_MANAGER="zypper"
        info_msg "Detected openSUSE system"
    else
        error_msg "Could not detect package manager."
    fi

    info_msg "Detected OS: $OS"
    info_msg "Detected Version: $VERSION"
    if [ -n "$CODENAME" ]; then
        info_msg "Detected Codename: $CODENAME"
    fi
    info_msg "Using package manager: $PKG_MANAGER"

    # Verify we have the minimum required information
    if [ "$PKG_MANAGER" = "apt" ] && [ -z "$CODENAME" ]; then
        error_msg "Could not determine OS codename. Please report this issue."
    fi
}

# Function to install Docker
install_docker() {
    info_msg "Starting Docker installation..."

    case $PKG_MANAGER in
        apt)
            # Install prerequisites
            sudo apt-get update || error_msg "Failed to update package list."
            sudo apt-get install -y ca-certificates curl gnupg || error_msg "Failed to install prerequisites."

            # Add Docker's official GPG key
            sudo install -m 0755 -d /etc/apt/keyrings || error_msg "Failed to create keyrings directory."
            sudo curl -fsSL "https://download.docker.com/linux/$OS/gpg" -o /etc/apt/keyrings/docker.asc || error_msg "Failed to download Docker GPG key."
            sudo chmod a+r /etc/apt/keyrings/docker.asc || error_msg "Failed to set permissions on Docker GPG key."

            # Add the repository to Apt sources
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$OS ${CODENAME:-$VERSION_CODENAME} stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || error_msg "Failed to add Docker repository."

            sudo apt-get update || error_msg "Failed to update package list after adding Docker repository."

            # Install Docker
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || error_msg "Failed to install Docker packages."
            ;;
        dnf|yum)
            # Install prerequisites
            sudo $PKG_MANAGER install -y dnf-plugins-core || error_msg "Failed to install prerequisites."

            # Add Docker repository
            if [ "$OS" = "fedora" ]; then
                repo_url="https://download.docker.com/linux/fedora/docker-ce.repo"
            else
                repo_url="https://download.docker.com/linux/centos/docker-ce.repo"
            fi
            
            sudo $PKG_MANAGER config-manager --add-repo $repo_url || error_msg "Failed to add Docker repository."

            # Install Docker
            sudo $PKG_MANAGER install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || error_msg "Failed to install Docker packages."
            ;;
        pacman)
            # Arch Linux installation
            sudo pacman -Sy --noconfirm docker docker-compose || error_msg "Failed to install Docker packages."
            ;;
        zypper)
            # openSUSE installation
            sudo zypper addrepo https://download.docker.com/linux/opensuse/docker-ce.repo || error_msg "Failed to add Docker repository."
            sudo zypper refresh || error_msg "Failed to refresh repositories."
            sudo zypper install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin || error_msg "Failed to install Docker packages."
            ;;
        *)
            error_msg "Unsupported package manager: $PKG_MANAGER"
            ;;
    esac

    # Start and enable Docker service
    if command -v systemctl >/dev/null 2>&1; then
        info_msg "Starting Docker service..."
        sudo systemctl enable --now docker || error_msg "Failed to enable and start Docker service."
    fi

    # Add current user to docker group
    if ! grep -q docker /etc/group; then
        sudo groupadd docker || error_msg "Failed to create docker group."
    fi
    sudo usermod -aG docker $USER || warning_msg "Failed to add user to docker group (may need to do this manually)."

    success_msg "Docker installed successfully!"
    info_msg "You may need to log out and back in for group changes to take effect."
    info_msg "To test Docker, run: docker run hello-world"
}

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
    warning_msg "This script should not be run as root. We'll request sudo when needed."
    exit 1
fi

# Check for sudo access
if ! sudo -v; then
    error_msg "You need sudo privileges to run this script."
fi

# Main execution
check_network
detect_architecture
check_requirements
backup_existing_config
detect_os
install_docker
verify_installation