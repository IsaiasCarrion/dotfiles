-- ~/.config/nvim/lua/plugins.lua

return require("lazy").setup({

  -- Tema: Similar a VS Code (dark)
  {
  "navarasu/onedark.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("onedark").setup({
      style = "dark", -- Puedes cambiar a 'deep', 'cool', 'warm', 'nord', 'monokai'
    })
    require("onedark").load()
  end,
},

  -- Barra de estado: Es la barra inferior con información útil
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- Depende de los íconos
  },

  -- Íconos para archivos
  { "nvim-tree/nvim-web-devicons" },

  -- Explorador de archivos (el "sidebar")
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup()
    end,
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.x", -- Importante para asegurar una versión estable
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- Autocompletado y LSP (el corazón de la inteligencia de VS Code)
  {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "neovim/nvim-lspconfig",
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lsp",
    },
  },

  -- Sintaxis moderna (Treesitter)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "c", "lua", "vim", "javascript", "typescript", "python" },
        sync_install = false,
        auto_install = true,
        highlight = { enable = true },
      })
    end,
  },

})



