import subprocess

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
            "Failed to install required dependencies for CRI-O."
        )
        print("System updated and prerequisites installed.")
    except Exception as e:
        print(f"Error during system update and dependency installation: {e}")
        raise

def configure_crio_repository():
    print("Configuring CRI-O repository...")
    try:
        os_version = "xUbuntu_22.04"
        cri_version = "1.28"
        gpg_key_url = "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Release.key"
        gpg_key_path = "/usr/share/keyrings/libcontainers-archive-keyring.gpg"

        # Import GPG key
        run_command(
            f"curl -fsSL {gpg_key_url} | sudo gpg --dearmor -o {gpg_key_path}",
            "Failed to import GPG key for CRI-O repository."
        )

        # Add repositories
        crio_repo = (
            f"deb [signed-by={gpg_key_path}] "
            f"https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/{os_version}/ /"
        )
        cri_version_repo = (
            f"deb [signed-by={gpg_key_path}] "
            f"https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/{cri_version}/{os_version}/ /"
        )
        run_command(
            f"echo \"{crio_repo}\" | sudo tee /etc/apt/sources.list.d/libcontainers.list",
            "Failed to add base CRI-O repository."
        )
        run_command(
            f"echo \"{cri_version_repo}\" | sudo tee /etc/apt/sources.list.d/cri-o.list",
            "Failed to add version-specific CRI-O repository."
        )

        run_command("sudo apt-get update -qq", "Failed to update the package list after adding repositories.")
        print("CRI-O repository configured successfully.")
    except Exception as e:
        print(f"Error configuring CRI-O repository: {e}")
        raise

def main():
    try:
        update_system_and_install_dependencies()
        configure_crio_repository()
        print("Control plane setup completed successfully.")
    except Exception as e:
        print(f"Setup failed: {e}")

if __name__ == "__main__":
    main()
