#!/bin/bash
# Usage: curl -fsSL https://raw.githubusercontent.com/Norbert515/vide_cli/main/scripts/install.sh | bash

set -e

REPO="Norbert515/vide_cli"
VIDE_HOME="$HOME/.vide"
VIDE_BIN_DIR="$VIDE_HOME/bin"
WRAPPER_DIR="$HOME/.local/bin"
BINARY_NAME="vide"

# Detect OS and architecture
detect_platform() {
    local os=$(uname -s)
    local arch=$(uname -m)

    case "$os" in
        Darwin)
            # macOS - detect architecture
            case "$arch" in
                arm64)
                    echo "macos-arm64"
                    ;;
                x86_64)
                    echo "macos-x64"
                    ;;
                *)
                    echo "Unsupported macOS architecture: $arch" >&2
                    exit 1
                    ;;
            esac
            ;;
        Linux)
            case "$arch" in
                x86_64)
                    echo "linux-x64"
                    ;;
                *)
                    echo "Unsupported architecture: $arch" >&2
                    exit 1
                    ;;
            esac
            ;;
        *)
            echo "Unsupported operating system: $os" >&2
            exit 1
            ;;
    esac
}

# Fetch latest version from GitHub API
get_latest_version() {
    curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | \
        grep '"tag_name":' | \
        sed -E 's/.*"v([^"]+)".*/\1/'
}

# Verify SHA256 checksum of a file
verify_checksum() {
    local file="$1"
    local expected_hash="$2"

    # Compute actual hash using shasum (available on macOS and most Linux)
    local actual_hash=$(shasum -a 256 "$file" | cut -d' ' -f1)

    if [ "$actual_hash" != "$expected_hash" ]; then
        echo "Checksum verification failed!" >&2
        echo "  Expected: $expected_hash" >&2
        echo "  Actual:   $actual_hash" >&2
        return 1
    fi
    return 0
}

# Fetch expected checksum for a file from SHA256SUMS.txt
get_expected_checksum() {
    local version="$1"
    local filename="$2"
    local checksum_url="https://github.com/$REPO/releases/download/v$version/SHA256SUMS.txt"

    # Download SHA256SUMS.txt and extract the hash for the target file
    # Format is: "hash  filename" (two spaces between hash and filename)
    curl -fsSL "$checksum_url" | grep "  $filename$" | cut -d' ' -f1
}

# Detect user's shell and return the appropriate config file
get_shell_config() {
    case "$SHELL" in
        */zsh)
            echo "$HOME/.zshrc"
            ;;
        */bash)
            # Prefer .bashrc, but use .bash_profile on macOS if .bashrc doesn't exist
            if [ -f "$HOME/.bashrc" ]; then
                echo "$HOME/.bashrc"
            else
                echo "$HOME/.bash_profile"
            fi
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

# Prompt user to add PATH and handle response
prompt_add_to_path() {
    local shell_config=$(get_shell_config)
    local shell_config_name=$(basename "$shell_config")

    echo ""
    echo "$WRAPPER_DIR is not in your PATH."
    printf "Add it to your shell config ($shell_config_name)? [Y/n] "

    # Read a single character, default to Y if just Enter
    read -r response
    response=${response:-Y}

    case "$response" in
        [Yy]*)
            # Create the config file if it doesn't exist
            if [ ! -f "$shell_config" ]; then
                touch "$shell_config"
            fi

            # Add PATH export
            echo "" >> "$shell_config"
            echo "# Added by vide installer" >> "$shell_config"
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$shell_config"

            echo ""
            echo "Added PATH to $shell_config"
            echo "Restart your terminal or run: source $shell_config"
            ;;
        *)
            echo ""
            echo "To add it manually, add this line to your shell config:"
            echo ""
            echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
            ;;
    esac
}

# Create the wrapper script that applies updates before launching
create_wrapper_script() {
    cat > "$WRAPPER_DIR/$BINARY_NAME" << 'WRAPPER_EOF'
#!/bin/bash
VIDE_HOME="$HOME/.vide"
VIDE_BIN="$VIDE_HOME/bin/vide"
PENDING_UPDATE="$VIDE_HOME/updates/pending/vide"
PENDING_META="$VIDE_HOME/updates/pending/metadata.json"

# Apply pending update if exists
if [ -f "$PENDING_UPDATE" ]; then
    mv "$PENDING_UPDATE" "$VIDE_BIN"
    chmod +x "$VIDE_BIN"
    rm -f "$PENDING_META"
fi

exec "$VIDE_BIN" "$@"
WRAPPER_EOF
    chmod +x "$WRAPPER_DIR/$BINARY_NAME"
}

main() {
    echo "Installing vide..."

    # Detect platform
    local platform=$(detect_platform)
    echo "Detected platform: $platform"

    # Get latest version
    echo "Fetching latest version..."
    local version=$(get_latest_version)
    if [ -z "$version" ]; then
        echo "Failed to fetch latest version" >&2
        exit 1
    fi
    echo "Latest version: $version"

    # Create directories
    mkdir -p "$VIDE_BIN_DIR"
    mkdir -p "$WRAPPER_DIR"

    # Handle migration: remove old binary at ~/.local/bin/vide if it's not a wrapper
    if [ -f "$WRAPPER_DIR/$BINARY_NAME" ]; then
        # Check if it's already a wrapper script (starts with #!/bin/bash and contains VIDE_HOME)
        if head -n 5 "$WRAPPER_DIR/$BINARY_NAME" 2>/dev/null | grep -q "VIDE_HOME"; then
            echo "Wrapper script already exists, updating..."
        else
            echo "Migrating existing binary to new location..."
            # Move the old binary to the new location
            mv "$WRAPPER_DIR/$BINARY_NAME" "$VIDE_BIN_DIR/$BINARY_NAME"
        fi
    fi

    # Determine download file and URL based on platform
    local download_file
    local is_tarball=false

    case "$platform" in
        macos-arm64)
            download_file="vide-macos-arm64.tar.gz"
            is_tarball=true
            ;;
        macos-x64)
            download_file="vide-macos-x64.tar.gz"
            is_tarball=true
            ;;
        linux-x64)
            download_file="vide-linux-x64"
            ;;
    esac

    local download_url="https://github.com/$REPO/releases/download/v$version/$download_file"
    echo "Downloading from: $download_url"

    # Fetch expected checksum
    echo "Fetching checksum..."
    local expected_checksum=$(get_expected_checksum "$version" "$download_file")
    if [ -z "$expected_checksum" ]; then
        echo "Failed to fetch checksum for $download_file" >&2
        exit 1
    fi

    if [ "$is_tarball" = true ]; then
        # Download and extract tarball
        local temp_dir=$(mktemp -d)
        curl -fsSL "$download_url" -o "$temp_dir/$download_file"

        # Verify checksum before extraction
        echo "Verifying checksum..."
        if ! verify_checksum "$temp_dir/$download_file" "$expected_checksum"; then
            rm -rf "$temp_dir"
            exit 1
        fi

        tar -xzf "$temp_dir/$download_file" -C "$temp_dir"
        mv "$temp_dir/vide" "$VIDE_BIN_DIR/$BINARY_NAME"
        rm -rf "$temp_dir"
    else
        # Download raw binary to temp location first
        local temp_dir=$(mktemp -d)
        curl -fsSL "$download_url" -o "$temp_dir/$download_file"

        # Verify checksum before moving to final location
        echo "Verifying checksum..."
        if ! verify_checksum "$temp_dir/$download_file" "$expected_checksum"; then
            rm -rf "$temp_dir"
            exit 1
        fi

        mv "$temp_dir/$download_file" "$VIDE_BIN_DIR/$BINARY_NAME"
        rm -rf "$temp_dir"
    fi

    # Make executable
    chmod +x "$VIDE_BIN_DIR/$BINARY_NAME"

    # Create wrapper script
    create_wrapper_script

    echo ""
    echo "Successfully installed vide $version"
    echo "  Binary: $VIDE_BIN_DIR/$BINARY_NAME"
    echo "  Wrapper: $WRAPPER_DIR/$BINARY_NAME"

    # Check if wrapper directory is in PATH
    if [[ ":$PATH:" != *":$WRAPPER_DIR:"* ]]; then
        prompt_add_to_path
    fi

    echo ""
    echo "Run 'vide --help' to get started"
}

main
