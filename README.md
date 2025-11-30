# Scalpel

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
- **Rust** >= 1.70 (if building from source)
- **Python** >= 3.8 (for model inference)
- **AI Model**: Compatible with any model that `llama.cpp` supports (e.g., CodeLlama, DeepSeek-Coder, Qwen-Coder)

> **Note**: The server spawns `llama.cpp` as a subprocess for model inference.

## 📦 Installation

### 1. Install the Neovim Plugin

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "yourusername/scalpel.nvim",
  dependencies = {
    "hrsh7th/nvim-cmp",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("scalpel").setup({
      port = 3000,  -- Port for AI server (default: 3000)
    })
  end,
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  "yourusername/scalpel.nvim",
  requires = {
    "hrsh7th/nvim-cmp",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("scalpel").setup({
      port = 3000,
    })
  end,
}
```

### 2. Build the AI Server

#### Option A: Build from Source (Recommended)

```bash
cd scalpel.nvim/server
cargo build --release
```

The binary will be at `server/target/release/scalpel`. The plugin auto-detects this path.

#### Option B: Download Pre-built Binary (Coming Soon)

```bash
# Download the appropriate binary for your platform
curl -LO https://github.com/yourusername/scalpel.nvim/releases/latest/download/scalpel-macos-arm64

# Make it executable
chmod +x scalpel-macos-arm64

# Move to a permanent location
mv scalpel-macos-arm64 ~/.local/bin/scalpel
```

Then configure the plugin to use the binary:

```lua
require("scalpel").setup({
  binary_path = vim.fn.expand("~/.local/bin/scalpel"),
  port = 3000,
})
```

### 3. Set Up the AI Model

1. **Download a Model**

Download a `llama.cpp`-compatible model (e.g., GGUF format):

```bash
# Example: Download CodeLlama 7B (GGUF)
mkdir -p models
cd models
wget https://huggingface.co/TheBloke/CodeLlama-7B-GGUF/resolve/main/codellama-7b.Q4_K_M.gguf
```

2. **Set Environment Variables**

The server expects these environment variables:

```bash
export SCALPEL_PORT=3000
export SCALPEL_MODEL_PATH="/path/to/your/model.gguf"
export SCALPEL_LLAMA_CPP_PATH="/path/to/llama.cpp/build/bin/llama-server"
```

Add these to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.) to persist them.

> **Finding llama.cpp**: Install from [llama.cpp](https://github.com/ggerganov/llama.cpp):
> ```bash
> git clone https://github.com/ggerganov/llama.cpp
> cd llama.cpp
> make
> # Binary will be at ./build/bin/llama-server
> ```

### 4. Configure nvim-cmp

Update your `nvim-cmp` configuration to integrate Scalpel:

```lua
local cmp = require("cmp")

cmp.setup({
  -- Add Scalpel to your sources
  sources = {
    { name = "scalpel" },   -- Scalpel AI predictions (fallback)
    { name = "nvim_lsp" },  -- Your LSP
    { name = "buffer" },
    { name = "path" },
  },
  
  -- Add Scalpel comparator for boosting
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
  
  -- Add visual indicator for boosted items
  formatting = {
    format = function(entry, vim_item)
      -- Apply Scalpel formatting (adds ⚡ to boosted items)
      vim_item = require("scalpel.formatter").format(entry, vim_item)
      
      -- Optional: chain other formatters (e.g., lspkind)
      -- vim_item = require("lspkind").cmp_format(...)(entry, vim_item)
      
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
  -- Path to server binary (nil = auto-detect in server/target/release/)
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
- Verify llama.cpp is accessible: `$SCALPEL_LLAMA_CPP_PATH --version`
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
