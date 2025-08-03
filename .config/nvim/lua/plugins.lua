-- ~/.config/nvim/lua/plugins.lua
return require("lazy").setup({ -- Tema: Similar a VS Code (dark)
{
    "Mofiqul/vscode.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("vscode").setup({
        -- Configuración opcional para el tema
        transparent = false,
        italic_comments = true,
      })
      require("vscode").load()
    end,
  },

  -- Para que los iconos de archivos se vean bien en el explorador
  { "nvim-tree/nvim-web-devicons" },

  -- Lualine (barra de estado), que se integra bien con el tema de VS Code
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "auto"
        }
      })
    end
  },

  -- El resto de tus plugins (Telescope, LSP, Treesitter, etc.)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" }
  },

  -- Autocompletado y LSP
  {"williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim", "neovim/nvim-lspconfig"}, {
    "hrsh7th/nvim-cmp",
    dependencies = {"L3MON4D3/LuaSnip", "saadparwaiz1/cmp_luasnip", "hrsh7th/cmp-nvim-lsp"}
  },

  -- Sintaxis moderna (Treesitter)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {"c", "lua", "vim", "javascript", "typescript", "python"},
        sync_install = false,
        auto_install = true,
        highlight = { enable = true }
      })
    end
  },

-- Jupytext
{
    "goerz/jupytext.nvim",
    opts = {}
},

})

