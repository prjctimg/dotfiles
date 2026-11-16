local languages = {
  -- Bundled with Neovim
  'lua',
  'vimdoc',
  'markdown',
  'markdown_inline',
  'query',
  'wgsl',
  -- Personal language set: TS/JS, Rust, Assembly, shell/fish, configs
  'typescript',
  'tsx',
  'javascript',
  'bash',
  'fish',
  'rust',
  'asm',
  'json',
  'toml',
  'yaml',
  'gray',
  'css',
  'html',
  'python',
  'nix',
  'git_config',
  'gitignore',
  'diff',
  'regex',
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      -- Grayscale parser registration
      --
      -- 'tree-sitter-gray' is not part of nvim-treesitter's parser registry, so
      -- it has to be added to `require('nvim-treesitter.parsers')` from the
      -- `User TSUpdate` hook. nvim-treesitter fires that event (and reloads its
      -- parser table) before every install/update, which is why the entry can
      -- be registered here even though this file loads later than lazy.nvim's
      -- spec collection.
      --
      -- The upstream repo commits `node_modules`, which makes the tarball large
      -- and often slow to download. A sparse copy of the pinned revision is
      -- vendored in 'parsers/tree-sitter-gray/' instead, so `:TSInstall gray`
      -- and `:TSUpdate` build locally. The URL is the fallback for checkouts
      -- that do not have the vendored directory.
      --
      -- `queries = 'queries'` installs the upstream `highlights.scm`. The extra
      -- queries this config needs (folds, indents, textobjects, locals) live in
      -- 'queries/gray/' and are picked up from the config directory.
      local gray_parser = vim.fs.joinpath(vim.fn.stdpath('config'), 'parsers', 'tree-sitter-gray')
      local gray_install = {
        revision = 'f0c9dae1e97050cb8ac1c177b1b2a53abf9cbcff',
        queries = 'queries',
      }
      if vim.uv.fs_stat(gray_parser) then
        gray_install.path = gray_parser
      else
        gray_install.url = 'https://github.com/grayscale-lang/tree-sitter-gray'
      end
      vim.api.nvim_create_autocmd('User', {
        pattern = 'TSUpdate',
        callback = function()
          require('nvim-treesitter.parsers').gray = { install_info = gray_install }
        end,
        desc = 'Register the Grayscale tree-sitter parser',
      })

      -- Define languages which will have parsers installed and auto enabled.
      local isnt_installed = function(lang)
        return #vim.api.nvim_get_runtime_file('parser/' .. lang .. '.*', false) == 0
      end
      local to_install = vim.tbl_filter(isnt_installed, languages)
      if #to_install > 0 then
        vim.api.nvim_create_autocmd('VimEnter', {
          once = true,
          callback = function()
            require('nvim-treesitter').install(to_install)
          end,
          desc = 'Install missing tree-sitter parsers',
        })
      end

      -- Parse 'mdx' files (Markdown + JSX) with the built-in 'markdown' parser so
      -- highlighting and render-markdown work there.
      vim.treesitter.language.register('markdown', 'mdx')
      -- `.gray` and `.grayscale` both use the 'gray' filetype (see 'init.lua'),
      -- so the parser name and the filetype already match. Registering it is
      -- explicit and also covers `:setfiletype grayscale`-style overrides.
      vim.treesitter.language.register('gray', { 'gray', 'grayscale' })

      -- Enable tree-sitter after opening a file for a target language
      local filetypes = {}
      for _, lang in ipairs(languages) do
        for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
          table.insert(filetypes, ft)
        end
      end
      Config.new_autocmd('FileType', filetypes, function(ev)
        vim.treesitter.start(ev.buf)
      end, 'Start tree-sitter')
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    event = { 'BufReadPre', 'BufNewFile' },
  },
}
