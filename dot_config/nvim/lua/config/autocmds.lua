local autocmd = vim.api.nvim_create_autocmd

autocmd({ "FileType", "BufEnter" }, {

  pattern = { "*.fish" },
  callback = function()
    vim.lsp.enable({ "fish_lsp" })
  end,
})

-- Auto hover with line diagnostics
-- Track last symbol name to avoid duplicate triggers
local last_symbol = nil

-- Utility: get diagnostics for current line
local function get_line_diagnostics()
  local bufnr = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  return vim.diagnostic.get(bufnr, { lnum = line })
end

-- Utility: show diagnostics in a floating window
local function show_diagnostics(diags)
  if #diags == 0 then
    return
  end
  local msg = {}
  for _, d in ipairs(diags) do
    table.insert(msg, d.message)
  end
  vim.lsp.util.open_floating_preview(msg, "plaintext", { border = "rounded" })
end

-- Helper: get symbol name under cursor
local function symbol_at_cursor()
  local cword = vim.fn.expand("<cword>")
  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(bufnr)
  return file .. ":" .. cword
end

-- Main handler
local function show_signature_or_hover()
  local bufnr = vim.api.nvim_get_current_buf()
  local params = vim.lsp.util.make_position_params(0, "utf-8")

  local symbol_id = symbol_at_cursor()
  if symbol_id == last_symbol then
    return -- avoid duplicate trigger if still on same symbol
  end
  last_symbol = symbol_id

  local diags = get_line_diagnostics()

  -- Try signatureHelp first
  vim.lsp.buf_request(bufnr, "textDocument/signatureHelp", params, function(err, result)
    if err or not result or not result.signatures or vim.tbl_isempty(result.signatures) then
      -- fallback to hover if no signature
      vim.lsp.buf_request(bufnr, "textDocument/hover", params, function(err2, result2)
        if err2 or not result2 or not result2.contents then
          if #diags > 0 then
            show_diagnostics(diags)
          end
          return
        end

        local contents = vim.lsp.util.convert_input_to_markdown_lines(result2.contents)
        if #diags > 0 then
          table.insert(contents, "")
          table.insert(contents, "Diagnostics:")
          for _, d in ipairs(diags) do
            table.insert(contents, "- " .. d.message)
          end
        end
        vim.lsp.util.open_floating_preview(contents, "markdown", { border = "rounded" })
      end)
      return
    end

    -- We have signature help
    local contents = vim.lsp.util.convert_signature_help_to_markdown_lines(result)
    if contents and not vim.tbl_isempty(contents) then
      if #diags > 0 then
        table.insert(contents, "")
        table.insert(contents, "Diagnostics:")
        for _, d in ipairs(diags) do
          table.insert(contents, "- " .. d.message)
        end
      end
      vim.lsp.util.open_floating_preview(contents, "markdown", { border = "rounded" })
    elseif #diags > 0 then
      show_diagnostics(diags)
    end
  end)
end

autocmd({ "CursorHold" }, {
  pattern = {
    "*.sh",
    "*.fish",
    "*.ts",
    "*.js",
    "*.tsx",
    "*.jsx",
    "*.cjs",
    "*.zig",
    "*.lua",
    "*.go",
    "*.css",
    "*.yml",
    "*.yaml",
    "*.wglsl",
  },
  callback = function()
    -- Skip if floating window already showing (user is reading hover/sig)
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local config = vim.api.nvim_win_get_config(win)
      if config.relative and config.relative ~= "" then
        return
      end
    end
    show_signature_or_hover()
  end,
  group = vim.api.nvim_create_augroup("LspSignatureHoverDiagnostics", { clear = true }),
})
