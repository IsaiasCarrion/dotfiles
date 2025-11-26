-- ~/.config/nvim/init.lua

-- =============================================================================
-- 1. SETTINGS BÁSICOS
-- =============================================================================
vim.g.mapleader = " " 
vim.g.maplocalleader = " "

vim.opt.number = true           
vim.opt.relativenumber = true   
vim.opt.mouse = 'a'             
vim.opt.clipboard = 'unnamedplus' 
vim.opt.breakindent = true
vim.opt.undofile = true         
vim.opt.ignorecase = true       
vim.opt.smartcase = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.termguicolors = true    

-- =============================================================================
-- 2. GESTOR DE PAQUETES (Lazy.nvim)
-- =============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- =============================================================================
-- 3. PLUGINS
-- =============================================================================
require("lazy").setup({
  
  -- TEMA: Afterglow (Definitivo)
  { 
    "danilo-augusto/vim-afterglow", 
    priority = 1000, 
    config = function() 
      vim.g.afterglow_inherit_background = 1 -- Integra el fondo con Kitty
      vim.cmd.colorscheme("afterglow") 
    end 
  },

  -- UI: Barra de estado
  { 
    'nvim-lualine/lualine.nvim', 
    opts = { 
      options = { 
        icons_enabled = true, 
        theme = 'auto', -- Detectará Afterglow automáticamente
        component_separators = '|',
        section_separators = '',
      } 
    } 
  },

  -- COMENTARIOS
  {
    'numToStr/Comment.nvim',
    opts = {},
    lazy = false,
  },

  -- NAVEGACIÓN: Telescope
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim', { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' } },
    config = function()
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = 'Buscar Archivos' })
      vim.keymap.set('n', '<C-f>', builtin.live_grep, { desc = 'Buscar Texto' })
      vim.keymap.set('n', '<leader>b', builtin.buffers, { desc = 'Buffers' })
    end
  },

  -- SYNTAX: Treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup {
        ensure_installed = { "python", "lua", "vim", "bash", "markdown", "sql", "json" },
        auto_install = true,
        highlight = { enable = true },
      }
    end
  },

  -- INTELIGENCIA: LSP & Autocompletado
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'hrsh7th/nvim-cmp',       
      'hrsh7th/cmp-nvim-lsp',
      'L3MON4D3/LuaSnip',       
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "pyright" }, 
        handlers = {
          function(server_name)
            local capabilities = require('cmp_nvim_lsp').default_capabilities()
            require('lspconfig')[server_name].setup { capabilities = capabilities }
          end,
        }
      })
      
      local cmp = require 'cmp'
      cmp.setup {
        snippet = { expand = function(args) require('luasnip').lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
          ['<C-n>'] = cmp.mapping.select_next_item(),
          ['<C-p>'] = cmp.mapping.select_prev_item(),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm { select = true },
          ['<Tab>'] = cmp.mapping.select_next_item(),
        }),
        sources = { { name = 'nvim_lsp' }, { name = 'luasnip' }, { name = 'path' } },
      }
    end
  },

  -- FORMATEO
  {
    'stevearc/conform.nvim',
    opts = {
      notify_on_error = false,
      format_on_save = { timeout_ms = 500, lsp_fallback = true },
      formatters_by_ft = {
        python = { "isort", "black" },
      },
    },
  },
})

-- =============================================================================
-- 4. KEYMAPS (VS Code Style)
-- =============================================================================

-- RECUERDA: Ejecuta 'stty -ixon' en tu terminal si Ctrl+S congela la pantalla
vim.keymap.set({ 'n', 'i', 'v' }, '<C-s>', '<cmd>w<cr><esc>', { desc = 'Guardar' })
vim.keymap.set('n', '<C-q>', '<cmd>q<cr>', { desc = 'Salir' })
vim.keymap.set('n', '<C-S-q>', '<cmd>q!<cr>', { desc = 'Forzar Salida' })

-- Deshacer/Rehacer
vim.keymap.set('n', '<C-z>', 'u', { desc = 'Undo' })
vim.keymap.set('i', '<C-z>', '<C-o>u', { desc = 'Undo' })
vim.keymap.set('n', '<C-y>', '<C-r>', { desc = 'Redo' })

-- Clipboard del sistema
vim.keymap.set({'n', 'v'}, '<C-c>', '"+y', { desc = 'Copiar' })
vim.keymap.set({'n', 'v'}, '<C-x>', '"+d', { desc = 'Cortar' })
vim.keymap.set({'n'}, '<C-v>', '"+p', { desc = 'Pegar' })
vim.keymap.set({'i'}, '<C-v>', '<C-r>+', { desc = 'Pegar Insert' })

-- Mover líneas (Alt+Flechas)
vim.keymap.set("n", "<M-Down>", ":m .+1<CR>==", { desc = "Mover abajo" })
vim.keymap.set("n", "<M-Up>", ":m .-2<CR>==", { desc = "Mover arriba" })
vim.keymap.set("v", "<M-Down>", ":m '>+1<CR>gv=gv", { desc = "Mover bloque abajo" })
vim.keymap.set("v", "<M-Up>", ":m '<-2<CR>gv=gv", { desc = "Mover bloque arriba" })

-- Comentarios (Ctrl+/)
vim.keymap.set('n', '<C-_>', function() require('Comment.api').toggle.linewise.current() end, { desc = 'Comentar' })
vim.keymap.set('v', '<C-_>', "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", { desc = 'Comentar bloque' })
