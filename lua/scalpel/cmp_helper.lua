--[[
Scalpel nvim-cmp Setup Helper
=============================

Programmatically integrates Scalpel with nvim-cmp by:
1. Overriding cmp.setup() to inject Scalpel
2. Calling cmp.setup() ourselves to establish baseline
--]]

local M = {}

function M.setup(opts)
  local cmp = require("cmp")

  -- Register Scalpel source
  cmp.register_source("scalpel", require("scalpel.cmp").new())

  -- Register Scalpel comparator globally
  cmp.config.compare.scalpel = require("scalpel.comparator")

  local scalpel_formatter = require("scalpel.formatter")

  -- Store original setup
  local original_setup = cmp.setup

  -- Override cmp.setup to inject Scalpel
  cmp.setup = function(user_config)
    user_config = user_config or {}

    -- Merge user's sources with Scalpel
    if not user_config.sources then
      user_config.sources = {}
    end
    table.insert(user_config.sources, 1, { name = "scalpel" })

    -- Merge user's sorting with Scalpel
    if not user_config.sorting then
      user_config.sorting = {}
    end
    local user_comparators = user_config.sorting.comparators or {}
    user_config.sorting.comparators = vim.list_extend(
      { cmp.config.compare.scalpel },
      user_comparators
    )

    -- Merge user's formatting with Scalpel
    if not user_config.formatting then
      user_config.formatting = {}
    end
    local user_format = user_config.formatting.format
    user_config.formatting.format = function(entry, vim_item)
      vim_item = scalpel_formatter.format(entry, vim_item)
      if user_format then
        vim_item = user_format(entry, vim_item)
      end
      return vim_item
    end

    -- Call original setup with modified config
    return original_setup(user_config)
  end

  -- Call cmp.setup() ourselves to establish baseline with Scalpel
  original_setup({
    sources = {
      { name = "scalpel" },
      { name = "nvim_lsp" },
      { name = "luasnip" },
      { name = "path" },
    },
    sorting = {
      comparators = {
        cmp.config.compare.scalpel,
        cmp.config.compare.offset,
        cmp.config.compare.exact,
        cmp.config.compare.score,
        cmp.config.compare.recently_used,
        cmp.config.compare.locality,
        cmp.config.compare.kind,
        cmp.config.compare.length,
        cmp.config.compare.order,
      },
    },
    formatting = {
      format = function(entry, vim_item)
        vim_item = scalpel_formatter.format(entry, vim_item)
        return vim_item
      end,
    },
  })

  -- Ensure nvim-lsp source is registered
  local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
  if cmp_nvim_lsp_ok and type(cmp_nvim_lsp) == "table" and cmp_nvim_lsp.setup then
    cmp_nvim_lsp.setup()
  end
end

return M
