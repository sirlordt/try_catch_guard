#!/bin/bash
set -e  # Exit on error

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install packages if they don't exist
ensure_package_installed() {
    local package_name="$1"
    local command_name="${2:-$1}"  # Default to package name if command name not provided
    
    if ! command_exists "$command_name"; then
        echo "$command_name is not installed. Attempting to install $package_name..."
        
        # Check if we have sudo access
        if command_exists sudo; then
            sudo apt-get update
            sudo apt-get install -y "$package_name"
        else
            echo "Error: sudo is not available. Please install $package_name manually."
            exit 1
        fi
        
        # Verify installation
        if ! command_exists "$command_name"; then
            echo "Error: Failed to install $package_name. Please install it manually."
            exit 1
        fi
        
        echo "$package_name installed successfully."
    else
        echo "$command_name is already installed."
    fi
}

# Check and install required packages
ensure_package_installed "cmake"
ensure_package_installed "python3-pip" "pip3"

# Check for Conan
if ! command_exists conan; then
    echo "Conan is not installed. Attempting to install via pip..."
    pip3 install conan
    
    # Verify installation
    if ! command_exists conan; then
        echo "Error: Failed to install Conan. Please install it manually."
        exit 1
    fi
    
    echo "Conan installed successfully."
fi

# Print commands before executing them
set -x

# Check if Conan profile exists and create one if it doesn't
if ! conan profile list | grep -q default; then
    echo "No default Conan profile found. Creating one..."
    conan profile detect
fi

# Create build directory if it doesn't exist
mkdir -p build
cd build

# Install dependencies with Conan and generate CMake files (Conan 2.x approach)
conan install .. --output-folder=. --build=missing

# Configure and build with CMake
cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake -DCMAKE_BUILD_TYPE=Release
cmake --build .

# Return to project root
cd ..

# Turn off command echoing before the final message (redirect to /dev/null to hide the command itself)
{ set +x; } 2>/dev/null

# Run the application
echo -e "\nRunning the application:"
./build/cpp_project
