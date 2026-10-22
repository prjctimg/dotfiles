-- ┌───────────────────────┐
-- │ Personal plugins     │
-- └───────────────────────┘
--
-- Ported from the previous LazyVim setup. Everything that depended on
-- 'snacks.nvim' was dropped; the rest is kept as-is.
--
-- `render-markdown.nvim` and `image.nvim` decorate the buffer itself, so they
-- load on the same read trigger as tree-sitter and the language servers -- before
-- the first screen is drawn. The rest are helpers and statusline sections, so
-- they wait for `VeryLazy`.

return {
  -- render-markdown.nvim: rendered Markdown/MDX in the buffer itself
  {
    'MeanderingProgrammer/render-markdown.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('render-markdown').setup({
        enabled = true,
        render_modes = { 'n', 'i', 'c', 't', 'x' },
        debounce = 100,
      })
    end,
  },

  -- image.nvim: inline image rendering in markdown/mdx. Uses the `kitty` backend
  -- (Ghostty implements the Kitty graphics protocol) and needs ImageMagick.
  {
    '3rd/image.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      -- Make the ImageMagick probes fail softly *before* `setup()` builds the
      -- processor, so a file ImageMagick cannot read is skipped instead of
      -- raising an uncaught error from a libuv callback.
      pcall(function()
        require('image_processor').harden()
      end)

      local ok, err = pcall(function()
        require('image').setup({
          backend = 'kitty',
          -- A remote image that cannot be downloaded is a broken link, not a
          -- reason to interrupt the editor.
          ignore_download_error = true,
          integrations = {
            markdown = {
              enabled = true,
              clear_in_insert_mode = true, -- hide images while typing to avoid flicker
              only_render_image_at_cursor = false, -- render all images in the viewport
              filetypes = { 'markdown', 'vimwiki', 'mdx' },
            },
            -- Not used here. Each of them queries tree-sitter for a parser
            -- that is not installed and downloads remote images on every
            -- redraw.
            asciidoc = { enabled = false },
            typst = { enabled = false },
            neorg = { enabled = false },
            syslang = { enabled = false },
          },
        })
      end)
      if not ok then
        vim.notify('image.nvim: setup failed: ' .. tostring(err), vim.log.levels.ERROR)
      end
    end,
  },

  {
    'prjctimg/stoic.nvim',
    event = 'VeryLazy',
    config = function()
      pcall(function()
        require('stoic').setup({})
      end)
    end,
  },
  {
    'prjctimg/p5.nvim',
    event = 'VeryLazy',
  },
  {
    '2kabhishek/nerdy.nvim',
    event = 'VeryLazy',
    -- nerdy.nvim (glyph picker; may need a picker integration at runtime)
    config = function()
      pcall(function()
        require('nerdy').setup({ max_recents = 30, add_default_keybindings = true })
      end)
    end,
  },
  {
    'allaman/emoji.nvim',
    event = 'VeryLazy',
    config = function()
      -- No `plugin_path` override any more: the previous config had to point it at
      -- `stdpath('data')..'/site/pack/core/opt/'` because that is where `vim.pack`
      -- installs plugins. emoji.nvim's own default already is
      -- `stdpath('data')..'/lazy/'`, which is exactly lazy.nvim's layout.
      pcall(function()
        require('emoji').setup({ enable_cmp_integration = false, ui_select = true })
      end)
    end,
  },
  {
    'epwalsh/pomo.nvim',
    event = 'VeryLazy',
    config = function()
      require('pomo').setup({
        update_interval = 1000,
        notifiers = {
          { name = 'Default', opts = { sticky = false, title_icon = '󱎫', text_icon = '󰄉' } },
          { name = 'System' },
        },
        timers = { Break = { { name = 'System' } } },
        sessions = {
          pomodoro = {
            { name = 'Work', duration = '25m' },
            { name = 'Short Break', duration = '5m' },
            { name = 'Work', duration = '25m' },
            { name = 'Short Break', duration = '5m' },
            { name = 'Work', duration = '25m' },
            { name = 'Short Break', duration = '5m' },
            { name = 'Work', duration = '25m' },
            { name = 'Long Break', duration = '15m' },
          },
        },
      })
    end,
  },

  -- gtm.nvim (music player UI; talks to the `gtmd` daemon over a Unix socket).
  -- The plugin's own 'plugin/gtm.lua' loader auto-setups with defaults whenever
  -- the plugin is loaded outside an explicit spec. Opt out by setting
  -- `vim.g.loaded_gtm` in `init` (which runs *before* the plugin files are
  -- sourced), so the explicit setup below is the only one. (`gtm.setup` is
  -- idempotent, so even a load-order edge case ends with one registration.)
  {
    'prjctimg/gtm.nvim',
    event = 'VeryLazy',
    init = function()
      vim.g.loaded_gtm = true
    end,
    config = function()
      local ok, gtm = pcall(require, 'gtm')
      if not ok then
        return
      end
      gtm.setup({
        statusline_format = 'compact',
        theme = { reactive = true, intensity = 0.22, scope = 'global' },
      })
    end,
  },
}
