--[[
Scalpel nvim-cmp Setup Helper
==============================

Simplifies nvim-cmp integration by automatically configuring the comparator,
formatter, and source. Users only need to call setup_cmp() with their existing
sources, rather than manually wiring up 4 separate pieces.

Before (manual setup):
  require("scalpel").setup()
  cmp.setup({
    sources = { { name = "scalpel" }, { name = "nvim_lsp" } },
    sorting = {
      comparators = { require("scalpel.comparator"), ... }
    },
    formatting = {
      format = function(entry, vim_item)
        vim_item = require("scalpel.formatter").format(entry, vim_item)
        return vim_item
      end
    }
  })

After (simplified):
  require("scalpel").setup_cmp({
    sources = { { name = "nvim_lsp" }, { name = "buffer" } }
  })
--]]

local M = {}

--- Merges Scalpel into an existing nvim-cmp configuration
--- @param user_config table User's nvim-cmp config (sources, sorting, formatting, etc.)
--- @return table Merged configuration with Scalpel integrated
function M.merge_cmp_config(user_config)
  local cmp = require("cmp")
  local comparator = require("scalpel.comparator")
  local formatter = require("scalpel.formatter")

  local config = vim.tbl_deep_extend("force", {}, user_config or {})

  -- 1. Prepend scalpel source to sources list
  local user_sources = config.sources or {}
  config.sources = vim.list_extend({ { name = "scalpel" } }, user_sources)

  -- 2. Prepend scalpel comparator to sorting.comparators
  local sorting = config.sorting or {}
  local user_comparators = sorting.comparators or {
    cmp.config.compare.offset,
    cmp.config.compare.exact,
    cmp.config.compare.score,
    cmp.config.compare.recently_used,
    cmp.config.compare.locality,
    cmp.config.compare.kind,
    cmp.config.compare.length,
    cmp.config.compare.order,
  }
  sorting.comparators = vim.list_extend({ comparator }, user_comparators)
  config.sorting = sorting

  -- 3. Wrap existing format function with scalpel formatter
  local user_formatting = config.formatting or {}
  local user_format = user_formatting.format

  user_formatting.format = function(entry, vim_item)
    -- Apply scalpel formatting first (adds lightning bolt)
    vim_item = formatter.format(entry, vim_item)
    -- Then apply user's custom formatting if any
    if user_format then
      vim_item = user_format(entry, vim_item)
    end
    return vim_item
  end
  config.formatting = user_formatting

  return config
end

return M
