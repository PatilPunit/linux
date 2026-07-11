import subprocess

def run_command(command):
    """Runs a shell command and returns output"""
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    return result.stdout + result.stderr

def install_package(package_name):
    """Installs a package via pacman"""
    return run_command(f"sudo pacman -S --noconfirm {package_name}")