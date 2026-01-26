# Scalpel

[![Release](https://img.shields.io/github/v/release/ericwang07/scalpel.nvim?style=flat-square)](https://github.com/ericwang07/scalpel.nvim/releases)
[![Build](https://img.shields.io/github/actions/workflow/status/ericwang07/scalpel.nvim/release.yml?style=flat-square)](https://github.com/ericwang07/scalpel.nvim/actions)
[![License](https://img.shields.io/github/license/ericwang07/scalpel.nvim?style=flat-square)](LICENSE)

Local AI code completion for Neovim. Boosts LSP completions using llama.cpp.

https://github.com/user-attachments/assets/a0963985-3c76-43c7-be4e-f115947edc23

## Features

- Local inference via llama.cpp (no cloud, no telemetry)
- Integrates with nvim-cmp
- Boosts LSP completions that match AI predictions
- Visual indicator (⚡) for AI-boosted items
- Non-blocking with debounced requests

## Requirements

- Neovim >= 0.9.0
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [llama.cpp](https://github.com/ggerganov/llama.cpp) (`llama-server` must be in PATH)
- GGUF model (Qwen2.5-Coder recommended)

## Installation

### 1. Install the CLI

```bash
curl -sSL https://raw.githubusercontent.com/ericwang07/scalpel.nvim/main/scripts/install.sh | bash
```

Add to your PATH:

```bash
export PATH="$PATH:$HOME/.local/bin"
```

#### Alternative: Build from Source

```bash
cd server && cargo build --release
```

#### Alternative: Download Pre-built Binary

```bash
# macOS Apple Silicon
curl -LO https://github.com/ericwang07/scalpel.nvim/releases/latest/download/scalpel-macos-arm64
chmod +x scalpel-macos-arm64 && mv scalpel-macos-arm64 ~/.local/bin/scalpel-server

# macOS Intel
curl -LO https://github.com/ericwang07/scalpel.nvim/releases/latest/download/scalpel-macos-x86_64
chmod +x scalpel-macos-x86_64 && mv scalpel-macos-x86_64 ~/.local/bin/scalpel-server

# Linux x86_64
curl -LO https://github.com/ericwang07/scalpel.nvim/releases/latest/download/scalpel-linux-x86_64
chmod +x scalpel-linux-x86_64 && mv scalpel-linux-x86_64 ~/.local/bin/scalpel-server
```

Then download the wrapper script:

```bash
curl -sSL https://raw.githubusercontent.com/ericwang07/scalpel.nvim/main/scripts/scalpel -o ~/.local/bin/scalpel
chmod +x ~/.local/bin/scalpel
```

### 2. Install llama.cpp

The server requires `llama-server` from llama.cpp:

```bash
# macOS
brew install llama.cpp

# Linux (build from source)
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp && make -j
sudo cp llama-server /usr/local/bin/
```

Verify installation:
```bash
llama-server --version
```

### 3. Download a Model

| Model | Size | Speed | Quality | Download |
|-------|------|-------|---------|----------|
| **Qwen2.5-Coder-3B-Instruct (Q4_K_M)** | ~2GB | Fast | Great | [HuggingFace](https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF) |
| Qwen2.5-Coder-1.5B-Instruct (Q4_K_M) | ~1GB | Very Fast | Basic | [HuggingFace](https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF) |
| Qwen2.5-Coder-7B-Instruct (Q4_K_M) | ~4.5GB | Slow | Best | [HuggingFace](https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF) |

### 4. Configure Environment

Add to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.):

```bash
# Required
export SCALPEL_MODEL_PATH="/path/to/your/model.gguf"

# Optional (with defaults)
export SCALPEL_PORT=3000           # Server port
export SCALPEL_MAX_CONTEXT=1024    # Max context window
export SCALPEL_GPU_LAYERS=-1       # GPU layers (-1 = all)
```

### 5. Install the Plugin

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "ericwang07/scalpel.nvim",
  dependencies = {
    "hrsh7th/nvim-cmp",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("scalpel").setup_cmp({
      cmp_config = {
        sources = {
          { name = "nvim_lsp" },
          { name = "buffer" },
        },
      },
    })
  end,
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  "ericwang07/scalpel.nvim",
  requires = {
    "hrsh7th/nvim-cmp",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("scalpel").setup_cmp({
      cmp_config = {
        sources = {
          { name = "nvim_lsp" },
          { name = "buffer" },
        },
      },
    })
  end,
}
```

#### Manual nvim-cmp Setup

For more control over nvim-cmp configuration:

```lua
require("scalpel").setup()

local cmp = require("cmp")
cmp.setup({
  sources = {
    { name = "nvim_lsp" },
    { name = "buffer" },
  },
  sorting = {
    comparators = {
      require("scalpel.comparator"),  -- Boost AI predictions
      cmp.config.compare.offset,
      cmp.config.compare.exact,
      cmp.config.compare.score,
      cmp.config.compare.recently_used,
      cmp.config.compare.kind,
      cmp.config.compare.length,
      cmp.config.compare.order,
    },
  },
  formatting = {
    format = function(entry, vim_item)
      vim_item = require("scalpel.formatter").format(entry, vim_item)
      return vim_item
    end,
  },
})
```

## Usage

### Server Management

```bash
scalpel start   # Start server in background
scalpel stop    # Stop server
scalpel status  # Check if running
```

### Neovim Commands

```vim
:ScalpelHealth    " Check server status
:ScalpelToggle    " Toggle on/off
:ScalpelEnable    " Enable
:ScalpelDisable   " Disable
```

## Configuration

```lua
require("scalpel").setup({
  port = 3000,
  keymaps = {
    complete = "<C-k>",  -- Manual trigger
  },
})
```

## How It Works

Scalpel uses fill-based matching:

1. You type "con" → fetcher extracts this as the typed prefix
2. AI predicts "cat" (what should come after cursor)
3. LSP returns candidates like "concat", "configure", "console"
4. Matcher compares: "concat" minus "con" = "cat" → exact match
5. "concat" gets boosted to top with ⚡ indicator

## Architecture

### Components

- **Rust Server** (`server/`): Axum HTTP server managing llama.cpp subprocess
- **Neovim Plugin** (`lua/scalpel/`):
  - `fetcher.lua` - Debounces text changes, extracts context
  - `client.lua` - HTTP client for server
  - `state.lua` - Holds prediction and typed prefix
  - `matcher.lua` - Exact match on fill portion
  - `comparator.lua` - Boosts matching LSP items
  - `formatter.lua` - Adds ⚡ indicator

### Data Flow

```
TextChangedI → fetcher (debounce) → server → state → comparator → formatter
```

## Troubleshooting

### Server Not Running

```bash
scalpel start
curl -s http://localhost:3000/health  # Should return: OK
```

In nvim:
```vim
:ScalpelHealth  " Should show "Server is running on port 3000"
```

### Connection Refused

1. Check server status:
   ```bash
   scalpel status
   ```

2. Check port:
   ```bash
   echo $SCALPEL_PORT  # Should be 3000
   ```

3. Verify model path:
   ```bash
   echo $SCALPEL_MODEL_PATH  # Should point to .gguf file
   ```

4. Restart server:
   ```bash
   scalpel stop && scalpel start
   ```

### Port Already in Use

```bash
scalpel stop
scalpel start
```

### Model File Not Found

```bash
echo $SCALPEL_MODEL_PATH
ls -la $SCALPEL_MODEL_PATH
```

### Completions Not Appearing

1. Verify nvim-cmp: `:CmpStatus`
2. Check Scalpel comparator is in cmp sorting config
3. Ensure Insert mode (triggers on `TextChangedI`)
4. Wait 100ms after typing (debounce period)

### No Visual Indicators

- Verify formatter is in nvim-cmp config
- Check predictions are fetched: `:ScalpelComplete`

## License

MIT
