# Scalpel

[![Release](https://img.shields.io/github/v/release/ericwang07/scalpel.nvim?style=flat-square)](https://github.com/ericwang07/scalpel.nvim/releases)
[![Build](https://img.shields.io/github/actions/workflow/status/ericwang07/scalpel.nvim/release.yml?style=flat-square)](https://github.com/ericwang07/scalpel.nvim/actions)
[![License](https://img.shields.io/github/license/ericwang07/scalpel.nvim?style=flat-square)](LICENSE)

**AI-powered code completion for Neovim with hybrid LSP boosting**

Scalpel is a Neovim plugin that uses local AI models to predict code completions and intelligently boosts them in your LSP completion menu. Unlike traditional completion plugins that replace your LSP, Scalpel works *alongside* it, using fuzzy matching and smart ranking to surface AI predictions while keeping your existing LSP workflow intact.

## ✨ Features

- **🚀 Hybrid Architecture**: Boosts LSP items with AI predictions rather than replacing them
- **⚡ Progressive Enhancement**: LSP results appear instantly, AI boosting happens asynchronously
- **🎯 Fuzzy Matching**: Matches predictions using exact, prefix/suffix, and substring algorithms
- **🔄 Non-blocking**: Requests are debounced (100ms) and stale responses are discarded
- **🎨 Visual Indicators**: Boosted items are marked with ⚡ so you know which suggestions are AI-powered
- **🏠 100% Local**: All AI inference runs on your machine - no cloud, no telemetry

## 📋 Requirements

### Neovim Plugin
- **Neovim** >= 0.9.0
- **[nvim-cmp](https://github.com/hrsh7th/nvim-cmp)** - Completion engine
- **[plenary.nvim](https://github.com/nvim-lua/plenary.nvim)** - Lua utilities (for HTTP requests)

### AI Server
- **[llama.cpp](https://github.com/ggerganov/llama.cpp)** - The `llama-server` binary for model inference
- **AI Model**: GGUF format model (e.g., Qwen2.5-Coder, CodeLlama, DeepSeek-Coder)
- **Rust** >= 1.70 *(only if building server from source)*

> **Note**: If using pre-built binaries, you only need `llama-server` and a model file. No Rust or Python required.

## 📦 Installation

### 1. Install the Neovim Plugin

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

### 2. Build the AI Server

#### Option A: One-Line Install (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/ericwang07/scalpel.nvim/main/scripts/install.sh | bash
```

This downloads the binary and optionally a recommended model.

#### Option B: Build from Source

```bash
cd scalpel.nvim/server
cargo build --release
```

The binary will be at `server/target/release/scalpel`. The plugin auto-detects this path.

#### Option C: Download Pre-built Binary

```bash
# macOS Apple Silicon
curl -LO https://github.com/ericwang07/scalpel.nvim/releases/latest/download/scalpel-macos-arm64
chmod +x scalpel-macos-arm64 && mv scalpel-macos-arm64 ~/.local/bin/scalpel

# macOS Intel
curl -LO https://github.com/ericwang07/scalpel.nvim/releases/latest/download/scalpel-macos-x86_64
chmod +x scalpel-macos-x86_64 && mv scalpel-macos-x86_64 ~/.local/bin/scalpel

# Linux x86_64
curl -LO https://github.com/ericwang07/scalpel.nvim/releases/latest/download/scalpel-linux-x86_64
chmod +x scalpel-linux-x86_64 && mv scalpel-linux-x86_64 ~/.local/bin/scalpel
```

The plugin automatically finds `scalpel` in your PATH.

### 3. Set Up the AI Model

#### Recommended Models

| Model | Size | Speed | Quality | Download |
|-------|------|-------|---------|----------|
| Qwen2.5-Coder-1.5B-Instruct (Q4_K_M) | ~1GB | ⚡ Fast | Good | [HuggingFace](https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF) |
| Qwen2.5-Coder-3B-Instruct (Q4_K_M) | ~2GB | Fast | Better | [HuggingFace](https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF) |
| Qwen2.5-Coder-7B-Instruct (Q4_K_M) | ~4.5GB | Moderate | Best | [HuggingFace](https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF) |

```bash
# Download with huggingface-cli (recommended)
pip install huggingface_hub
huggingface-cli download Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF qwen2.5-coder-1.5b-instruct-q4_k_m.gguf --local-dir models

# Or with curl
mkdir -p models && cd models
curl -LO https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf
```




#### Environment Variables

Add these to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.):

```bash
# Required
export SCALPEL_MODEL_PATH="/path/to/your/model.gguf"

# Optional (with defaults)
export SCALPEL_PORT=3000           # Server port
export SCALPEL_MAX_CONTEXT=1024    # Max context window
export SCALPEL_GPU_LAYERS=-1       # GPU layers (-1 = all)
```

#### Install llama-server

Scalpel requires `llama-server` from llama.cpp to be in your PATH:

```bash
# macOS (Homebrew)
brew install llama.cpp

# Or build from source
git clone https://github.com/ggerganov/llama.cpp && cd llama.cpp
cmake -B build && cmake --build build --config Release
# Add build/bin to your PATH, or copy llama-server to ~/.local/bin/
```

### 4. Configure nvim-cmp

#### Simple Setup (Recommended)

Use `setup_cmp()` to automatically configure nvim-cmp with Scalpel:

```lua
-- In your lazy.nvim plugin spec:
{
  "ericwang07/scalpel.nvim",
  dependencies = { "hrsh7th/nvim-cmp", "nvim-lua/plenary.nvim" },
  config = function()
    require("scalpel").setup_cmp({
      cmp_config = {
        -- Your existing nvim-cmp sources
        sources = {
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" },
        },
      },
    })
  end,
}
```

This automatically adds the Scalpel source, comparator, and formatter.

#### Manual Setup (Advanced)

If you need more control over nvim-cmp configuration:

```lua
require("scalpel").setup()

local cmp = require("cmp")
cmp.setup({
  sources = {
    { name = "scalpel" },   -- Scalpel AI predictions (fallback)
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

## 🚀 Usage

### Automatic Completion

Scalpel runs automatically in the background:

1. Start typing in Insert mode
2. LSP completions appear immediately
3. After 100ms of typing pause, Scalpel fetches an AI prediction
4. Matching LSP items jump to the top with a ⚡ indicator

### Manual Commands

```vim
:ScalpelStart       " Start the AI server
:ScalpelStop        " Stop the AI server
:ScalpelRestart     " Restart the AI server
:ScalpelHealth      " Check server health
:ScalpelComplete    " Trigger manual completion (for testing)
```

### Configuration Options

```lua
require("scalpel").setup({
  -- Path to server binary (nil = auto-detect)
  -- Checks: 1) PATH, 2) server/target/release/ in plugin dir
  binary_path = nil,

  -- Server port (must match SCALPEL_PORT env var)
  port = 3000,

  -- Optional keymaps
  keymaps = {
    complete = "<C-k>",  -- Trigger manual completion
  },
})
```

## 🔧 Troubleshooting

### Server Won't Start

**Error**: `Scalpel server binary not found`

- Build the server: `cd server && cargo build --release`
- Or set `binary_path` in config to point to your binary

**Error**: Server starts but requests fail

- Check environment variables are set: `echo $SCALPEL_MODEL_PATH`
- Verify llama-server is in PATH: `which llama-server`
- Verify model file exists: `ls -la $SCALPEL_MODEL_PATH`
- Check server logs (currently silent - enable in `server.lua` for debugging)

### Completions Not Appearing

1. Verify nvim-cmp is working: `:CmpStatus`
2. Check Scalpel source is registered: Look for `scalpel` in `:CmpStatus` sources
3. Ensure you're in Insert mode (Scalpel only triggers on `TextChangedI`)
4. Wait 100ms after typing (debounce period)

### No Visual Indicators (⚡)

- Verify formatter is in your nvim-cmp config (see step 4 above)
- Check that predictions are being fetched: `:ScalpelComplete` should show a notification

## 📖 How It Works

Scalpel uses a **hybrid architecture**:

1. **Background Fetcher** (`fetcher.lua`): Listens to text changes, debounces for 100ms, fetches AI predictions
2. **Fuzzy Matcher** (`matcher.lua`): Scores completions (3=exact, 2=prefix/suffix, 1=substring)
3. **Comparator** (`comparator.lua`): Boosts matching LSP items to the top
4. **Formatter** (`formatter.lua`): Adds ⚡ to boosted items
5. **Fallback Source** (`cmp.lua`): Provides raw AI prediction when LSP has no suggestions

This design keeps your existing LSP workflow while adding AI intelligence on top.

## 📝 License

MIT

## 🙏 Acknowledgements

- [llama.cpp](https://github.com/ggerganov/llama.cpp) - Fast LLM inference
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) - Completion framework
