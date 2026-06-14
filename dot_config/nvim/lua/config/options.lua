local o, opt, wo, g = vim.o, vim.opt, vim.wo, vim.g

o.autoread = true
o.relativenumber = true
o.laststatus = 3
o.list = true
o.listchars = table.concat({ "extends:…", "nbsp:␣", "precedes:…", "tab:> " }, ",")
o.autoindent = true
o.shiftwidth = 2
o.tabstop = 2
o.expandtab = true
o.clipboard = "unnamedplus"
o.updatetime = 4000
o.spelllang = "en"
o.spelloptions = "camel"
opt.iskeyword:append("-")
opt.complete:append("kspell")

o.lazyredraw = true
o.scrolloff = 8
o.winbl = 0
o.pumblend = 0
o.cursorcolumn = false
vim.opt.guicursor = "a:block-Cursor/lCursor-blinkon0"
