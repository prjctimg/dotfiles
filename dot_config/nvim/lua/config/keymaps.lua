-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- ┌─────────────────┐
-- │ Custom mappings │
-- └─────────────────┘
--

-- General mappings ===========================================================

local opencode = require("opencode")
local nmap_leader = function(suffix, rhs, desc)
  vim.keymap.set("n", "<Leader>" .. suffix, rhs, { desc = desc })
end

local map = function(mode, key, cb)
  vim.keymap.set(mode, key, cb, { noremap = false, silent = true })
end

-- Function to create a mapping that starts visual mode and moves the cursor
local function v_mv(key)
  return function()
    if vim.o.selection == "inclusive" then
      vim.cmd("normal! v" .. key)
    else
      vim.cmd("normal! V" .. key) -- Use blockwise  visual mode for 'exclusive'
    end
  end
end
map("n", "<C-;>", ":")

map({ "n", "i", "v", "t", "x", "o" }, "<A-/>", function()
  opencode.toggle()
end)

map({ "n", "i", "v", "t", "x", "o" }, "<A-a>", function()
  opencode.ask("@this: ", { submit = true })
end)

map({ "n", "i", "v", "t", "x", "o" }, "<A-.>", function()
  opencode.select()
end)

require("mini.files").setup({
  mappings = {
    close = "<ESC>",
    go_in = "l",
    go_in_plus = "<CR>",
    go_out = "h",
    go_out_plus = "<BS>",
    mark_goto = "'",
    mark_set = "m",
    reset = "",
    reveal_cwd = "@",
    show_help = "g?",
    synchronize = "=",
    trim_left = "<",
    trim_right = ">",
  },
  windows = {
    -- Maximum number of windows to show side by side
    max_number = math.huge,
    -- Whether to show preview of file/directory under cursor
    preview = true,
    -- Width of focused window
    width_focus = 25,
    -- Width of non-focused window
    width_nofocus = 15,
    -- Width of preview window
    width_preview = 50,
  },
})
map({ "n", "i", "v", "t", "x", "o" }, "<A-e>", function()
  pcall(function()
    if not MiniFiles:close() then
      MiniFiles.open(vim.api.nvim_buf_get_name(0), false)
    end
  end)
end)
map({ "i", "n", "v" }, "<A-r>", ":IncRename ")
map({ "i", "n" }, "<A-\\>", function()
  vim.lsp.buf.code_action()
end)

map({ "i", "n" }, "<A-f>", function()
  local grug, ext, name = require("grug-far"), vim.bo.buftype == "" and vim.fn.expand("%:e"), "grug"
  if grug.has_instance(name) then
    grug.hide_instance(name)
  else
    grug.open({
      transient = true,
      prefills = {
        filesFilter = ext and ext ~= "" and "*." .. ext or nil,
      },
      instanceName = "grug",
      staticTitle = "Find  and Replace",
    })
  end
end)

map({ "n", "i", "v", "t", "x", "o" }, "<S-Left>", v_mv("h"))
map({ "n", "i", "v", "t", "x", "o" }, "<S-Up>", v_mv("k"))
map({ "n", "i", "v", "t", "x", "o" }, "<S-Down>", v_mv("j"))
map({ "n", "i", "v", "t", "x", "o" }, "<S-Right>", v_mv("l"))
map({ "n", "i", "v" }, "<C-a>", "<ESC>gg0v$G$")

map({ "n", "i", "v" }, "<ESC>", "<ESC><ESC>")
map({ "i", "n", "v", "x", "o" }, "<C-Tab>", "<cmd>bnext<CR>")
map({ "i", "n", "v", "x", "o" }, "<S-Tab>", "<cmd>bprevious<CR>")
local cfg_file = function(filename)
  return string.format("<Cmd>edit %s/%s<CR>", vim.fn.stdpath("config"), filename)
end
nmap_leader("ti", cfg_file("init.lua"), "init.lua")
nmap_leader("tk", cfg_file("lua/config/keymaps.lua"), "Keymaps config")
nmap_leader("tm", cfg_file("lua/plugins/addons.lua"), "Addons configuration")
nmap_leader("to", cfg_file("lua/config/options.lua"), "Global options")
nmap_leader("tp", cfg_file("lua/plugins/lazyvim.lua"), "Configuration for LazyVim default plugins")

nmap_leader("ta", cfg_file("lua/config/autocmds.lua"), "Autocmds")

local floaterm = function(cmd)
  return Snacks.terminal.toggle(cmd, {

    style = "float",
  })
end

map({ "n", "i", "x", "t", "v" }, "<C-/>", function()
  floaterm("fish")
end)

map({ "n", "i", "x", "t", "v" }, "<A-B>", function()
  floaterm("btop")
end)

map({ "n", "i", "x", "t", "v" }, "<A-G>", function()
  floaterm("gh dash")
end)

map({ "n", "i", "x", "t", "v" }, "<A-F>", function()
  floaterm("yazi")
end)

-- map({ "n", "i", "x", "t", "v" }, "<A-M>", function()
--   Snacks.terminal.toggle("nvlc /mnt/chromeos/MyFiles/", {
--
--     style = "float",
--   })
-- end)

map({ "n", "i" }, "<A-g>", function()
  Snacks.lazygit()
end)

map({ "n", "i" }, "<A-z>", function()
  Snacks.zen()
end)

map({ "n", "i" }, "<A-Z>", function()
  Snacks.dashboard()
end)

-- map({ "n", "i" }, "<A-o>", function()
--   require("outline").toggle({
--     focus_on_open = false,
--   })
-- end)
--
map({ "n", "i" }, "<C-q>", function()
  local is_buf = vim.api.nvim_buf_is_valid(0)

  if is_buf then
    vim.cmd("bd")
  else
    vim.cmd("close")
  end
end)

map({ "n", "i" }, "<A-1>", "<cmd>Nerdy<cr>")

map({ "n", "i" }, "<C-9>", "<cmd>restart<cr>")
map({ "n", "i" }, "<A-2>", "<cmd>InsertEmoji<cr>")

map({ "n", "i" }, "<A-,>", function()
  Snacks.scratch.open()
end)
local pickers = {
  { "diagnostics", "X" },
  { "commands", "c" },

  { "smart", "'" },
  { "diagnostics_buffer", "x" },
  { "undo", "u" },
  { "lsp_symbols", "s" },
  { "lsp_workspace_symbols", "S" },
  { "yanky", "y" },
  { "help", "h" },
  { "man", "m" },
  { "projects", "w" },
  { "lines", ";" },
  { "git_log", ":" },
  { "command_history", "H" },
  { "jumps", "j" },
  { "buffers", "b" },
  { "marks", "q" },
  { "colorschemes", "C" },
  { "lsp_references", "R" },
}

for _, value in pairs(pickers) do
  local opts = {}

  if value == "man" then
    opts = {
      confirm = function(picker, item)
        picker:close()
        if item then
          vim.schedule(function()
            local cmd = "vert " .. "Man " .. item.ref

            vim.cmd(cmd)
          end)
        end
      end,
    }
  end

  map({ "n", "i" }, "<A-" .. value[2] .. ">", function()
    Snacks.picker[value[1]](opts)
  end)
end
