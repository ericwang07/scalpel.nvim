local client = require("scalpel.client")

local source = {}

function source.new()
  return setmetatable({}, { __index = source })
end

function source:get_debug_name()
  return "scalpel"
end

function source:is_available()
  return true
end

function source:get_trigger_characters()
  -- vim.notify("Scalpel CMP: get_trigger_characters called", vim.log.levels.INFO)
  return { ".", ":", "(", "[", "=", ",", "{", " " }
end

function source:complete(params, callback)
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(win)
  local row, col = cursor[1] - 1, cursor[2] -- 0-indexed row

  -- Get all lines
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local text = table.concat(lines, "\n")

  -- Calculate cursor byte offset
  -- Note: This is a simplified offset calculation. For multi-byte chars, 
  -- we should be careful. But for now, let's split text at cursor.
  -- A robust way is to use vim.api.nvim_buf_get_text but that's 0.10+ specific for some args.
  
  -- Let's use a simpler approach: get text before and after cursor
  -- In Insert mode, cursor is BETWEEN characters (or rather, at the insertion point).
  -- So prefix should include text UP TO the cursor.
  local prefix_lines = vim.api.nvim_buf_get_text(buf, 0, 0, row, col, {})
  local suffix_lines = vim.api.nvim_buf_get_text(buf, row, col, -1, -1, {})
  
  local prefix = table.concat(prefix_lines, "\n")
  local suffix = table.concat(suffix_lines, "\n")
  local filetype = vim.bo[buf].filetype



  -- vim.notify("Scalpel CMP: Requesting completion...", vim.log.levels.INFO)
  client.complete(prefix, suffix, filetype, function(res, err)
    if err then
      vim.notify("Scalpel CMP error: " .. tostring(err), vim.log.levels.ERROR)
      callback({ items = {}, isIncomplete = false })
      return
    end

    if not res or not res.completion or res.completion == "" then
      -- vim.notify("Scalpel CMP: No completion returned", vim.log.levels.WARN)
      callback({ items = {}, isIncomplete = false })
      return
    end

    -- vim.notify("Scalpel CMP: Got completion: '" .. res.completion .. "'", vim.log.levels.INFO)
    
    local item = {
      label = "⚡ " .. res.completion, -- Visual prefix
      kind = require("cmp").lsp.CompletionItemKind.Event,
      detail = "Scalpel AI",
      documentation = {
        kind = "markdown",
        value = "### Scalpel Completion\n```" .. filetype .. "\n" .. res.completion .. "\n```"
      },
      insertText = res.completion, -- Actual text to insert (no prefix)
      sortText = "!" .. res.completion, -- Aggressive sort hack
      filterText = res.completion, -- Match against the code, ignoring the ⚡ prefix
    }

    -- vim.notify("Scalpel CMP: Returning item to cmp", vim.log.levels.INFO)
    callback({ items = { item }, isIncomplete = false })
  end)
end

return source
