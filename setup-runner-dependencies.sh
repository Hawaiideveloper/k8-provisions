#!/bin/bash

# Setup script for self-hosted runner dependencies
# This script installs the required tools for GitHub Actions workflows

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Function to detect package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v brew &> /dev/null; then
        echo "brew"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

# Function to install package
install_package() {
    local package=$1
    local pkg_manager=$(detect_package_manager)
    
    case $pkg_manager in
        "apt")
            sudo apt-get update
            sudo apt-get install -y "$package"
            ;;
        "yum")
            sudo yum install -y "$package"
            ;;
        "dnf")
            sudo dnf install -y "$package"
            ;;
        "brew")
            brew install "$package"
            ;;
        "pacman")
            sudo pacman -S --noconfirm "$package"
            ;;
        *)
            print_error "No supported package manager found"
            return 1
            ;;
    esac
}

print_header "Self-Hosted Runner Dependencies Setup"

print_status "Detecting system and package manager..."
OS=$(uname -s)
ARCH=$(uname -m)
PKG_MANAGER=$(detect_package_manager)

echo "OS: $OS"
echo "Architecture: $ARCH"
echo "Package Manager: $PKG_MANAGER"

# List of required tools
REQUIRED_TOOLS=(
    "curl"
    "wget"
    "git"
    "python3"
    "pip3"
)

# List of optional tools (for enhanced functionality)
OPTIONAL_TOOLS=(
    "shellcheck"
    "nslookup"
    "dig"
    "ping"
    "jq"
)

print_header "Installing Required Tools"

for tool in "${REQUIRED_TOOLS[@]}"; do
    print_status "Checking $tool..."
    if command -v "$tool" &> /dev/null; then
        echo "  ✅ $tool is already installed"
    else
        print_warning "$tool not found, attempting to install..."
        if install_package "$tool"; then
            print_status "✅ $tool installed successfully"
        else
            print_error "❌ Failed to install $tool"
            echo "Please install $tool manually"
        fi
    fi
done

print_header "Installing Optional Tools"

for tool in "${OPTIONAL_TOOLS[@]}"; do
    print_status "Checking $tool..."
    if command -v "$tool" &> /dev/null; then
        echo "  ✅ $tool is already installed"
    else
        print_warning "$tool not found, attempting to install..."
        if install_package "$tool"; then
            print_status "✅ $tool installed successfully"
        else
            print_warning "⚠️  Failed to install $tool (optional)"
            echo "Workflows will still work but with reduced functionality"
        fi
    fi
done

print_header "Python Dependencies"

print_status "Checking Python environment..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "  ✅ Python: $PYTHON_VERSION"
    
    # Check pip
    if command -v pip3 &> /dev/null; then
        echo "  ✅ pip3 is available"
    else
        print_warning "pip3 not found, attempting to install..."
        if install_package "python3-pip"; then
            print_status "✅ pip3 installed successfully"
        else
            print_error "❌ Failed to install pip3"
        fi
    fi
else
    print_error "❌ Python3 not found"
    print_status "Attempting to install Python3..."
    if install_package "python3"; then
        print_status "✅ Python3 installed successfully"
    else
        print_error "❌ Failed to install Python3"
    fi
fi

print_header "Testing Network Connectivity"

print_status "Testing basic connectivity..."
if command -v curl &> /dev/null; then
    if curl -s --connect-timeout 5 https://httpbin.org/get &> /dev/null; then
        echo "  ✅ HTTP connectivity working"
    else
        print_warning "⚠️  HTTP connectivity test failed"
    fi
else
    print_warning "⚠️  curl not available for connectivity test"
fi

print_status "Testing DNS resolution..."
if command -v nslookup &> /dev/null; then
    if nslookup github.com &> /dev/null; then
        echo "  ✅ DNS resolution working"
    else
        print_warning "⚠️  DNS resolution test failed"
    fi
elif command -v dig &> /dev/null; then
    if dig github.com &> /dev/null; then
        echo "  ✅ DNS resolution working (using dig)"
    else
        print_warning "⚠️  DNS resolution test failed"
    fi
else
    print_warning "⚠️  No DNS tools available"
fi

print_header "Testing Python Scripts"

print_status "Testing Python script execution..."
if command -v python3 &> /dev/null; then
    if [ -f "hello_world.py" ]; then
        if python3 -c "import sys, platform, datetime, json, os" 2>/dev/null; then
            echo "  ✅ Python imports working"
        else
            print_warning "⚠️  Some Python imports failed"
        fi
    else
        echo "  ℹ️  hello_world.py not found, skipping script test"
    fi
else
    print_error "❌ Python3 not available for testing"
fi

print_header "Setup Complete"

print_status "Dependency installation completed!"
echo ""
echo "📋 Summary:"
echo "  ✅ Required tools checked/installed"
echo "  ✅ Optional tools checked/installed"
echo "  ✅ Python environment verified"
echo "  ✅ Network connectivity tested"
echo ""
echo "🚀 Your self-hosted runner should now be ready for GitHub Actions workflows!"
echo ""
echo "📝 Note: If any tools failed to install, you may need to install them manually"
echo "   or the workflows will run with reduced functionality."
echo ""
echo "🔧 To install missing tools manually:"
case $PKG_MANAGER in
    "apt")
        echo "   sudo apt-get install <package-name>"
        ;;
    "yum")
        echo "   sudo yum install <package-name>"
        ;;
    "dnf")
        echo "   sudo dnf install <package-name>"
        ;;
    "brew")
        echo "   brew install <package-name>"
        ;;
    "pacman")
        echo "   sudo pacman -S <package-name>"
        ;;
esac 