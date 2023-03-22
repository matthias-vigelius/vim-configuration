vim.cmd(":colorscheme tempus_day")

local set = vim.opt

set.smartindent=true
set.tabstop=3
set.shiftwidth=3
set.expandtab=true
set.makeprg="cmake --build ../build_clang/Debug --target all"

set.splitbelow = true

set.ignorecase = true
set.smartcase = true
set.gdefault = true

vim.keymap.set('n', '<space>wo', "<C-W>o")
vim.keymap.set('n', '<space>wh', "<C-W>h")
vim.keymap.set('n', '<space>wj', "<C-W>j")
vim.keymap.set('n', '<space>wk', "<C-W>k")
vim.keymap.set('n', '<space>wl', "<C-W>l")

-- bootstrap packer
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()


-- packer
require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

 -- Configurations for Nvim LSP
  use 'neovim/nvim-lspconfig'

 -- semantic highlight clangd
  use 'adam-wolski/nvim-lsp-clangd-highlight'

 -- repl
  --use {'hkupty/iron.nvim'}


  -- markdown
  -- use({ "iamcco/markdown-preview.nvim", run = "cd app && npm install", setup = function() vim.g.mkdp_filetypes = { "markdown" } end, ft = { "markdown" }, })

  use 'nvim-treesitter/nvim-treesitter'

  use 'jpalardy/vim-slime'

  -- quarto
   use( { 'quarto-dev/quarto-nvim',
  requires = {
      'jmbuhr/otter.nvim',
    }})

  if packer_bootstrap then
    require('packer').sync()
  end
end)

-- language server
-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
--  vim.keymap.set('n', '<space>wl', function()
--    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
--  end, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)
  vim.keymap.set('v', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)

  vim.keymap.set('n', '<space>s', vim.lsp.buf.document_symbol, bufopts)
  vim.keymap.set('n', '<space>o', vim.lsp.buf.workspace_symbol, bufopts)

  -- syntax highlighting
  -- vim.lsp.semantic_tokens.start(client, bufnr)
end

local lsp_flags = {
  -- This is the default in Nvim 0.7+
  debounce_text_changes = 150,
}


require'lspconfig'.clangd.setup{
    on_attach = on_attach,
    flags = lsp_flags,
}

require'quarto'.setup{
  debug = false,
  closePreviewOnExit = true,
  lspFeatures = {
    enabled = true,
    languages = { 'r', 'python', 'julia' },
    diagnostics = {
      enabled = true,
      triggers = { "BufWrite" }
    },
    completion = {
      enabled = false,
    },
  },
  keymap = {
    hover = 'K',
    definition = 'gd'
  }
}

require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all" (the four listed parsers should always be installed)
  ensure_installed = { "markdown" },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = true,

  -- List of parsers to ignore installing (for "all")
  ignore_install = { "javascript" },

  ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
  -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

  highlight = {
    -- `false` will disable the whole extension
    enable = true,

    -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
    -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
    -- the name of the parser)
    -- list of language that will be disabled
    disable = { "c", "rust" },
    -- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
    disable = function(lang, buf)
        local max_filesize = 100 * 1024 -- 100 KB
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > max_filesize then
            return true
        end
    end,

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
}

-- slime config (from https://github.com/jmbuhr/quarto-nvim-kickstarter/blob/main/lua/config/keymap.lua)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.b.slime_cell_delimiter = "```"
vim.g.slime_target = "tmux"

local nmap = function(key, effect)
  vim.keymap.set('n', key, effect, { silent = true, noremap = true })
end

nmap('<leader><cr>', '<Plug>SlimeSendCell')

-- semantic highlighting (doesn't seem to be working yet..)
-- local nvim_lsp_clangd_highlight = require'nvim-lsp-clangd-highlight'
-- 
-- require'lspconfig'.clangd.setup{
--  on_attach = on_attach,
--  flags = lsp_flags,
--     capabilities = {
--         textDocument = {
--             semanticHighlightingCapabilities = {
--                 semanticHighlighting = true
--             }
--         }
--     },
--     on_init = nvim_lsp_clangd_highlight.on_init
-- }

-- iron
-- local iron = require("iron.core")
-- 
-- iron.setup {
--   config = {
--     -- Whether a repl should be discarded or not
--     scratch_repl = true,
--     -- Your repl definitions come here
--     repl_definition = {
--       ipython = {
--         -- Can be a table or a function that
--         -- returns a table (see below)
--         command = {"ipython3"}
--       }
--     },
--     -- How the repl window will be displayed
--     -- See below for more information
--     --repl_open_cmd = require('iron.view').bottom(40),
--     repl_open_cmd = "botright 20 split"
--   },
--   -- Iron doesn't set keymaps by default anymore.
--   -- You can set them here or manually add keymaps to the functions in iron.core
--   keymaps = {
--     send_motion = "<space>sc",
--     visual_send = "<space>sc",
--     send_file = "<space>sf",
--     send_line = "<space>sl",
--     send_mark = "<space>sm",
--     mark_motion = "<space>mc",
--     mark_visual = "<space>mc",
--     remove_mark = "<space>md",
--     cr = "<space>s<cr>",
--     interrupt = "<space>s<space>",
--     exit = "<space>sq",
--     clear = "<space>cl",
--   },
--   -- If the highlight is on, you can change how it looks
--   -- For the available options, check nvim_set_hl
--   highlight = {
--     italic = true
--   },
--   ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
-- }
-- 
-- vim.keymap.set('n', '<space>rs', '<cmd>IronRepl<cr>')
-- vim.keymap.set('n', '<space>rr', '<cmd>IronRestart<cr>')
-- vim.keymap.set('n', '<space>rf', '<cmd>IronFocus<cr>')
-- vim.keymap.set('n', '<space>rh', '<cmd>IronHide<cr>')

-- markdown preview

