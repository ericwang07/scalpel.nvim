# Scalpel

[![Release](https://img.shields.io/github/v/release/ericwang07/scalpel.nvim?style=flat-square)](https://github.com/ericwang07/scalpel.nvim/releases)
[![Build](https://img.shields.io/github/actions/workflow/status/ericwang07/scalpel.nvim/release.yml?style=flat-square)](https://github.com/ericwang07/scalpel.nvim/actions)
[![License](https://img.shields.io/github/license/ericwang07/scalpel.nvim?style=flat-square)](LICENSE)

**Your code. Your models. Your machine.**

100% local AI completion built on llama.cpp. No cloud. No telemetry. Your code stays on your machine.

https://github.com/user-attachments/assets/a0963985-3c76-43c7-be4e-f115947edc23

---

## Why Scalpel?

### Privacy First
No API calls, no telemetry, no code sent anywhere. Your work stays on your machine.

### Your GPU = Your Compute
No subscriptions, no per-token fees. Download a model, run it forever.

### Works Offline
No internet required after initial model download. Code anywhere, anytime.

### Smarter Autocomplete
Scalpel doesn't generate patterns—it completes them. You're always in the loop, AI just extends what you're already writing.

### LSP-Grounded
Single-word completions backed by your language server. Lower hallucination, higher confidence.

---

## Who Is Scalpel For?

**Scalpel is for you if:**

- You need private completion (enterprise, sensitive repos, air-gapped systems)
- You work offline or in restricted environments
- You want one-time costs, not recurring API bills
- You prefer local-first tools and self-hosted software
- You want AI assistance without losing control of your code

**Before you install:**

- Only Qwen2.5-Coder models are officially supported (for now)
- Requires on-board GPU or patient CPU (3B models on integrated GPUs)
- Setup takes ~5 minutes

---

## How Scalpel Is Different

| | Scalpel | Cloud Solutions |
|---|---|---|
| Privacy | 100% local | Code sent to remote servers |
| Cost | One-time model download | Subscription/API fees |
| Offline | Works anywhere | Requires internet |
| Scope | Single-word completions | Full function generation |
| Philosophy | AI assists, you decide | AI writes, you review |

Scalpel is **smarter autocomplete**, not AI pair programming. You'll see
shorter, more accurate suggestions—grounded in your LSP and your context.

---

## Features

- 100% Local - No cloud, no exceptions
- Private - No telemetry, no API calls
- Offline Capable - No internet after model download
- LSP-Boosting - Enhances your existing completions
- Visual Indicators - Marks AI-suggested items
- Non-Blocking - Debounced with stale response discard
- Focused Scope - Single-word completions, lower hallucination
- llama.cpp Powered - Battle-tested inference engine

---

## Requirements

### Neovim Plugin
- Neovim >= 0.9.0
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) - Completion engine
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) - Lua utilities (for HTTP requests)

### AI Server
- llama.cpp inference (installed automatically with scalpel CLI)
- GGUF Model - Qwen2.5-Coder recommended (~2GB)

---

## Installation

### 1. Install Scalpel CLI

Run the install script:

```bash
curl -sSL https://raw.githubusercontent.com/ericwang07/scalpel.nvim/main/scripts/install.sh | bash
```

This downloads the `scalpel` command to `~/.local/bin/`. Add it to your PATH:

```bash
export PATH="$PATH:$HOME/.local/bin"
```

### 2. Build the AI Server

#### Option A: One-Line Install (Recommended)

The install script above downloads everything you need.

#### Option B: Build from Source

```bash
cd scalpel.nvim/server
cargo build --release
```

The binary will be at `server/target/release/scalpel`. The `scalpel` wrapper script automatically finds it.

#### Option C: Download Pre-built Binary

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

### 3. Set Up the AI Model

#### Recommended Models

| Model | Size | Speed | Quality | Download |
|-------|------|-------|---------|----------|
| **Qwen2.5-Coder-3B-Instruct (Q4_K_M)** | ~2GB | Fast | Great | [HuggingFace](https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF) |
| Qwen2.5-Coder-1.5B-Instruct (Q4_K_M) | ~1GB | Very Fast | Basic | [HuggingFace](https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF) |
| Qwen2.5-Coder-7B-Instruct (Q4_K_M) | ~4.5GB | Slow | Best | [HuggingFace](https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF) |

The 3B model offers the best balance of speed and code completion quality for local use.

#### Environment Variables

Add to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.):

```bash
# Required
export SCALPEL_MODEL_PATH="/path/to/your/model.gguf"

# Optional (with defaults)
export SCALPEL_PORT=3000           # Server port
export SCALPEL_MAX_CONTEXT=1024    # Max context window
export SCALPEL_GPU_LAYERS=-1       # GPU layers (-1 = all)
```

### 4. Install the Neovim Plugin

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

### 5. Configure nvim-cmp

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

---

## Usage

### Starting the Server

```bash
scalpel start
```

The server runs in the background. Use `scalpel status` to check if it's running.

### Checking Server Status

```bash
scalpel status
```

Or in Neovim:

```vim
:ScalpelHealth  " Check if server is running
```

### Stopping the Server

When you're done, stop the server to free resources:

```bash
scalpel stop
```

### Using Scalpel in Neovim

1. Open nvim - the plugin will check if the server is running
2. If the server is running, you'll see: `Scalpel: Server is running on port 3000`
3. If not, you'll see: `Scalpel: Server is not running`
4. Start typing in Insert mode - AI completions will be boosted

### Enabling/Disabling Scalpel

You can toggle Scalpel on/off without restarting Neovim:

```vim
:ScalpelToggle    " Toggle between enabled/disabled
:ScalpelEnable    " Enable Scalpel
:ScalpelDisable   " Disable Scalpel
```

When disabled, AI boosting is paused and no predictions are fetched.

---

## Configuration Options

```lua
require("scalpel").setup({
  -- Server port (must match SCALPEL_PORT env var)
  port = 3000,

  -- Optional keymaps
  keymaps = {
    complete = "<C-k>",  -- Trigger manual completion
  },
})
```

---

## FAQ

**Q: How is this different from Copilot?**
A: Copilot sends code to the cloud. Scalpel doesn't. You get privacy and offline support. The tradeoff: smaller models, shorter suggestions.

**Q: What models work?**
A: Qwen2.5-Coder only (for now). 3B is the sweet spot.

**Q: Do I need a GPU?**
A: On-board GPU helps. Apple Silicon, Intel/AMD integrated GPUs work fine. CPU-only is slower but still usable.

**Q: Setup time?**
A: About 5 minutes.

**Q: How good is the quality?**
A: It's autocomplete-level, not "write your whole file" level. Single-word to phrase suggestions. Fast, focused, and lower hallucination risk.

**Q: What inference engine does this use?**
A: llama.cpp. It's fast, well-maintained, and trusted by the local LLM community. The plugin manages the server—you just install and use.

---

## How It Works

Scalpel uses a **hybrid architecture**:

1. **Background Fetcher** (`fetcher.lua`): Listens to text changes, debounces for 100ms, fetches AI predictions
2. **Fuzzy Matcher** (`matcher.lua`): Scores completions (3=exact, 2=prefix/suffix, 1=substring)
3. **Comparator** (`comparator.lua`): Boosts matching LSP items to the top
4. **Formatter** (`formatter.lua`): Adds 󰌵 to boosted items

This design keeps your existing LSP workflow while adding AI intelligence on top.

---

## Troubleshooting

### Server Not Running

If you see `Scalpel: Server is not running` when opening nvim:

```bash
# Start the server
scalpel start

# Verify it's running
curl -s http://localhost:3000/health
# Should return: OK
```

In nvim, run:
```vim
:ScalpelHealth  " Should show "Server is running on port 3000"
```

### Connection Refused

If completions don't appear or you see connection errors:

1. Check if server is running:
   ```bash
   scalpel status
   ```

2. Check server port (default 3000):
   ```bash
   echo $SCALPEL_PORT  # Should be 3000
   ```

3. Verify model path is set:
   ```bash
   echo $SCALPEL_MODEL_PATH  # Should point to your .gguf file
   ```

4. Restart the server:
   ```bash
   scalpel stop
   scalpel start
   ```

### Port Already in Use

If you see "Address already in use":

```bash
# Stop existing server
scalpel stop

# Restart
scalpel start
```

### Server Uses Too Much Memory

```bash
# Stop the server when not using nvim
scalpel stop
```

### Model File Not Found

Ensure `SCALPEL_MODEL_PATH` is set correctly:

```bash
# Check current value
echo $SCALPEL_MODEL_PATH

# Verify file exists
ls -la $SCALPEL_MODEL_PATH

# Set if needed (add to shell profile)
export SCALPEL_MODEL_PATH="/path/to/your/model.gguf"
```

### Completions Not Appearing

1. Verify nvim-cmp is working: `:CmpStatus`
2. Verify Scalpel comparator is registered in your cmp sorting config
3. Ensure you're in Insert mode (Scalpel only triggers on `TextChangedI`)
4. Wait 100ms after typing (debounce period)

### No Visual Indicators

- Verify formatter is in your nvim-cmp config (see setup instructions above)
- Check that predictions are being fetched: `:ScalpelComplete` should show a notification

---

## License

MIT

## Acknowledgements

- [llama.cpp](https://github.com/ggerganov/llama.cpp) - Fast LLM inference
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) - Completion framework
