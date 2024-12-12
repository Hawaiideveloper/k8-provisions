import subprocess
import os

def run_command(command, error_message):
    try:
        subprocess.run(command, check=True, shell=True, text=True)
    except subprocess.CalledProcessError as e:
        print(f"Error: {error_message}\nCommand: {command}\n{e}")
        raise

# Function to check if a file exists and is valid
def validate_gpg_key(file_path):
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"GPG key file not found: {file_path}")
    try:
        result = subprocess.run(
            ["gpg", "--list-packets", file_path],
            check=True,
            text=True,
            capture_output=True
        )
        if "keyid" not in result.stdout:
            raise ValueError("Invalid GPG key file content.")
    except Exception as e:
        print(f"Error validating GPG key: {e}")
        raise

# Function to add CRI-O repository
def add_crio_repository():
    print("Adding CRI-O repository...")

    os_version = "xUbuntu_22.04"
    cri_version = "1.28"
    gpg_key_url = "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Release.key"
    gpg_key_path = "/usr/share/keyrings/libcontainers-archive-keyring.gpg"

    try:
        # Import GPG key
        print("Importing GPG key...")
        run_command(
            f"curl -fsSL {gpg_key_url} | sudo gpg --dearmor -o {gpg_key_path}",
            "Failed to import GPG key for CRI-O repository."
        )
        validate_gpg_key(gpg_key_path)

        # Add the base repository
        print("Adding base repository...")
        crio_repo = (
            f"deb [signed-by={gpg_key_path}] "
            f"https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/{os_version}/ /"
        )
        run_command(
            f"echo \"{crio_repo}\" | sudo tee /etc/apt/sources.list.d/libcontainers.list",
            "Failed to add base repository."
        )

        # Add version-specific repository
        print("Adding version-specific repository...")
        cri_version_repo = (
            f"deb [signed-by={gpg_key_path}] "
            f"https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/{cri_version}/{os_version}/ /"
        )
        run_command(
            f"echo \"{cri_version_repo}\" | sudo tee /etc/apt/sources.list.d/cri-o.list",
            "Failed to add version-specific repository."
        )

        # Update package list
        print("Updating package list...")
        run_command(
            "sudo apt-get update",
            "Failed to update package list after adding CRI-O repository."
        )
        print("CRI-O repository added successfully.")

    except Exception as e:
        print(f"Error adding CRI-O repository: {e}")
        raise

# Function to test the control plane setup
def test_control_plane_setup():
    try:
        print("Testing GPG key validation...")
        validate_gpg_key("/usr/share/keyrings/libcontainers-archive-keyring.gpg")
        print("GPG key validation passed.")
    except Exception as e:
        print(f"Test failed: {e}")

if __name__ == "__main__":
    try:
        add_crio_repository()
        test_control_plane_setup()
        print("Control plane setup completed successfully.")
    except Exception as e:
        print(f"Setup failed: {e}")
