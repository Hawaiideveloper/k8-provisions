import os
import sys
import subprocess

def check_root():
    if os.geteuid() != 0:
        print("This script must be run as root. Use 'sudo'.")
        sys.exit(1)

check_root()

def run_command(command, error_message):
    try:
        subprocess.run(command, check=True, shell=True, text=True)
    except subprocess.CalledProcessError as e:
        print(f"Error: {error_message}\nCommand: {command}\n{e}")
        raise

def update_system_and_install_dependencies():
    print("Updating system and installing prerequisites...")
    try:
        run_command("sudo apt-get update -qq", "Failed to update the package list.")
        run_command(
            "sudo apt-get install -y "
            "libbtrfs-dev containers-common git libassuan-dev libglib2.0-dev libc6-dev "
            "libgpgme-dev libgpg-error-dev libseccomp-dev libsystemd-dev libselinux1-dev "
            "pkg-config go-md2man cri-o-runc libudev-dev software-properties-common gcc make",
            "Failed to install required dependencies for building CRI-O."
        )
        print("System updated and prerequisites installed.")
    except Exception as e:
        print(f"Error during system update and dependency installation: {e}")
        raise

def ensure_make_installed():
    print("Ensuring 'make' is installed...")
    try:
        result = subprocess.run("make --version", shell=True, text=True, capture_output=True)
        if result.returncode != 0:
            print("'make' not found. Installing 'make'...")
            run_command("sudo apt-get install -y make", "Failed to install 'make'.")
    except Exception as e:
        print(f"Error ensuring 'make' is installed: {e}")
        raise

def ensure_go_installed():
    print("Ensuring Go is installed...")
    try:
        result = subprocess.run("go version", shell=True, text=True, capture_output=True)
        if result.returncode != 0:
            print("Go not found. Installing Go...")
            run_command(
                "sudo apt-get install -y golang",
                "Failed to install Go."
            )
    except Exception as e:
        print(f"Error ensuring Go is installed: {e}")
        raise

def clone_and_build_crio():
    print("Cloning and building CRI-O from source...")
    try:
        # Clone the CRI-O repository
        run_command(
            "git clone https://github.com/cri-o/cri-o.git", "Failed to clone the CRI-O repository."
        )

        # Change directory to the CRI-O repository
        os.chdir("cri-o")

        # Checkout the latest stable release
        run_command(
            "git checkout $(git describe --abbrev=0 --tags)",
            "Failed to checkout the latest stable release of CRI-O."
        )

        # Install dependencies using make
        run_command(
            "sudo make install.config", "Failed to install CRI-O configuration files."
        )
        run_command(
            "sudo make", "Failed to build CRI-O from source."
        )
        run_command(
            "sudo make install", "Failed to install CRI-O."
        )
        print("CRI-O built and installed successfully from source.")

    except Exception as e:
        print(f"Error building CRI-O from source: {e}")
        raise

def main():
    try:
        update_system_and_install_dependencies()
        ensure_make_installed()
        ensure_go_installed()
        clone_and_build_crio()
        print("Control plane setup completed successfully.")
    except Exception as e:
        print(f"Setup failed: {e}")

if __name__ == "__main__":
    main()
