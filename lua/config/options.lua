local o, opt, wo, g = vim.o, vim.opt, vim.wo, vim.g

-- o.shell = "fish"
o.autoread = true
o.relativenumber = true
o.laststatus = 3
o.list = true
o.listchars = table.concat({ "extends:…", "nbsp:␣", "precedes:…", "tab:> " }, ",")
o.autoindent = true
o.shiftwidth = 2
o.tabstop = 2
o.expandtab = true
o.scrolloff = 30
o.clipboard = "unnamedplus"
o.updatetime = 4000
o.spelllang = "en"
o.winbl = 25
o.spelloptions = "camel"
o.pumblend = 15
opt.iskeyword:append("-")
opt.complete:append("kspell")
opt.cursorcolumn = true
