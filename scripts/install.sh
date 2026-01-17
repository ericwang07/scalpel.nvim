#!/bin/bash
set -e

# Scalpel Installation Script
# Usage: curl -sSL https://raw.githubusercontent.com/ericwang07/scalpel.nvim/main/scripts/install.sh | bash

REPO="ericwang07/scalpel.nvim"
INSTALL_DIR="${SCALPEL_INSTALL_DIR:-$HOME/.local/bin}"
MODEL_DIR="${SCALPEL_MODEL_DIR:-$HOME/.local/share/scalpel/models}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Scalpel Installer                 ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
echo ""

# Detect platform
detect_platform() {
    local os arch
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m)
    
    case "$os" in
        darwin)
            case "$arch" in
                arm64) echo "macos-arm64" ;;
                x86_64) echo "macos-x86_64" ;;
                *) echo "unsupported" ;;
            esac
            ;;
        linux)
            case "$arch" in
                x86_64) echo "linux-x86_64" ;;
                *) echo "unsupported" ;;
            esac
            ;;
        *) echo "unsupported" ;;
    esac
}

PLATFORM=$(detect_platform)

if [ "$PLATFORM" = "unsupported" ]; then
    echo -e "${RED}Error: Unsupported platform. Please build from source.${NC}"
    echo "  cd server && cargo build --release"
    exit 1
fi

echo -e "Detected platform: ${GREEN}$PLATFORM${NC}"

# Get latest release
echo "Fetching latest release..."
LATEST_TAG=$(curl -sSL "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
    echo -e "${YELLOW}Warning: Could not find a release. Building from source instead.${NC}"
    echo ""
    echo "To build from source:"
    echo "  git clone https://github.com/$REPO"
    echo "  cd scalpel.nvim/server"
    echo "  cargo build --release"
    exit 1
fi

echo -e "Latest version: ${GREEN}$LATEST_TAG${NC}"

# Download binary
BINARY_URL="https://github.com/$REPO/releases/download/$LATEST_TAG/scalpel-$PLATFORM"
echo "Downloading binary from $BINARY_URL..."

mkdir -p "$INSTALL_DIR"
curl -sSL "$BINARY_URL" -o "$INSTALL_DIR/scalpel"
chmod +x "$INSTALL_DIR/scalpel"

echo -e "${GREEN}✓ Binary installed to $INSTALL_DIR/scalpel${NC}"

# Download model (optional)
echo ""
echo -e "${YELLOW}Would you like to download a recommended model? (y/n)${NC}"
read -r DOWNLOAD_MODEL

if [ "$DOWNLOAD_MODEL" = "y" ] || [ "$DOWNLOAD_MODEL" = "Y" ]; then
    mkdir -p "$MODEL_DIR"
    
    echo ""
    echo "Select a model:"
    echo "  1) Qwen2.5-Coder-3B-Instruct (Q4_K_M) - ~2GB [Recommended for best speed/quality balance]"
    echo "  2) Qwen2.5-Coder-1.5B-Instruct (Q4_K_M) - ~1GB [Faster but basic quality]"
    echo "  3) Qwen2.5-Coder-7B-Instruct (Q4_K_M) - ~4.5GB [Best quality but slower]"
    echo "  4) Skip model download"
    read -r MODEL_CHOICE
    
    case "$MODEL_CHOICE" in
        1)
            MODEL_URL="https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/qwen2.5-coder-3b-instruct-q4_k_m.gguf"
            MODEL_FILE="qwen2.5-coder-3b-instruct-q4_k_m.gguf"
            ;;
        2)
            MODEL_URL="https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf"
            MODEL_FILE="qwen2.5-coder-1.5b-instruct-q4_k_m.gguf"
            ;;
        3)
            MODEL_URL="https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/qwen2.5-coder-7b-instruct-q4_k_m.gguf"
            MODEL_FILE="qwen2.5-coder-7b-instruct-q4_k_m.gguf"
            ;;
        *)
            echo "Skipping model download."
            MODEL_FILE=""
            ;;
    esac
    
    if [ -n "$MODEL_FILE" ]; then
        echo "Downloading $MODEL_FILE..."
        
        # Try huggingface-cli first, fallback to curl
        if command -v huggingface-cli &> /dev/null; then
            huggingface-cli download "Qwen/Qwen2.5-Coder-${MODEL_FILE%%-q*}-Instruct-GGUF" "$MODEL_FILE" --local-dir "$MODEL_DIR"
        else
            curl -L "$MODEL_URL" -o "$MODEL_DIR/$MODEL_FILE"
        fi
        
        echo -e "${GREEN}✓ Model downloaded to $MODEL_DIR/$MODEL_FILE${NC}"
    fi
fi

# Print environment setup
echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
echo "Add these to your shell profile (~/.bashrc, ~/.zshrc):"
echo ""
echo -e "${YELLOW}export PATH=\"\$PATH:$INSTALL_DIR\"${NC}"
if [ -n "$MODEL_FILE" ]; then
    echo -e "${YELLOW}export SCALPEL_MODEL_PATH=\"$MODEL_DIR/$MODEL_FILE\"${NC}"
else
    echo -e "${YELLOW}export SCALPEL_MODEL_PATH=\"/path/to/your/model.gguf\"${NC}"
fi
echo ""
echo "Make sure llama-server is in your PATH (install via: brew install llama.cpp)"
echo ""
echo "Then configure Neovim (lazy.nvim):"
echo ""
echo '  {'
echo '    "ericwang07/scalpel.nvim",'
echo '    dependencies = { "hrsh7th/nvim-cmp", "nvim-lua/plenary.nvim" },'
echo '    config = function()'
echo '      require("scalpel").setup_cmp({'
echo '        cmp_config = {'
echo '          sources = { { name = "nvim_lsp" }, { name = "buffer" }, { name = "path" } },'
echo '        },'
echo '      })'
echo '    end,'
echo '  }'
echo ""
echo -e "For llama.cpp installation, see: ${GREEN}https://github.com/ggerganov/llama.cpp${NC}"
