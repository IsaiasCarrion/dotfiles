local opt = vim.opt
-- Map Leader
vim.g.mapleader = " "

-- Charge Plugins
vim.cmd([[packadd packer.nvim]])
require("packer").startup(function()
    -- Packer
    use("wbthomason/packer.nvim")
    use("neovim/nvim-lspconfig")
    use {
        "williamboman/nvim-lsp-installer",
        require = "neovim/nvim-lspconfig"
    }
    use("onsails/lspkind-nvim")
    use {
        "tami5/lspsaga.nvim",
        require = {"neovim/nvim-lspconfig"}
    }
    -- Theme
    use("tanvirtin/monokai.nvim")
    vim.cmd([[colorscheme monokai]])
    -- Linter
    use("nvim-treesitter/nvim-treesitter")
    require("nvim-treesitter.configs").setup({
        ensure_installed = {"bash", "c", "javascript", "json", "lua", "python", "typescript", "tsx", "css", "rust",
                            "java", "yaml", "markdown"},
        highlight = {
            enable = true
        }
    })
    use {
        'm-demare/hlargs.nvim',
        requires = {'nvim-treesitter/nvim-treesitter'}
    }

    -- Prettier
    use('neovim/nvim-lspconfig')
    use('jose-elias-alvarez/null-ls.nvim')
    use('MunifTanjim/prettier.nvim')
    -- Relativenumber
    use {
        "sitiom/nvim-numbertoggle",
        config = function()
            require("numbertoggle").setup()
        end
    }

    -- Commentary
    use 'b3nj5m1n/kommentary'

    -- Status Bar
    use {
        'nvim-lualine/lualine.nvim',
        requires = {
            'kyazdani42/nvim-web-devicons',
            opt = true
        }
    }
    use {'kyazdani42/nvim-web-devicons'}

    -- Buffer Line
    use {
        'akinsho/bufferline.nvim',
        tag = "v2.*",
        requires = 'kyazdani42/nvim-web-devicons'
    }

    -- FzF
    use("junegunn/fzf")
    use("junegunn/fzf.vim")

    -- Telescope
    use {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.0',
        -- or                            , branch = '0.1.x',
        requires = {{'nvim-lua/plenary.nvim'}}
    }

    -- Autocomplete LSP
    -- LSP
    use {
        'hrsh7th/nvim-cmp',
        requires = {'hrsh7th/cmp-nvim-lsp', 'hrsh7th/cmp-buffer', 'hrsh7th/cmp-path', 'hrsh7th/cmp-cmdline'}
    }

    -- snippets
    use {
        'hrsh7th/cmp-vsnip',
        requires = {'hrsh7th/vim-vsnip', 'rafamadriz/friendly-snippets'}
    }

    -- Autopairs
    use {
        "windwp/nvim-autopairs",
        config = function()
            require("nvim-autopairs").setup {}
        end
    }
    -- bracket autocompletion
    use 'vim-scripts/auto-pairs-gentle'

    -- nvim tree
    use {
        'nvim-tree/nvim-tree.lua',
        requires = {'nvim-tree/nvim-web-devicons' -- optional, for file icons
        },
        tag = 'nightly'
    }
    use {
        'lewis6991/gitsigns.nvim',
        config = function()
            require('gitsigns').setup()
        end
    }

end)

-- SETTINGS 
vim.wo.number = true
opt.number = true
opt.laststatus = 0
opt.smartindent = true
opt.autoindent = true
opt.expandtab = true
opt.smarttab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.showtabline = 4
opt.cursorline = true
opt.splitbelow = true
opt.splitright = true
opt.autochdir = true
opt.ignorecase = true
opt.smartcase = true
opt.clipboard = 'unnamedplus'
-- KEYBINDS

-- explorer
vim.api.nvim_set_keymap("n", "<leader>e", ":NvimTreeToggle<cr>", {
    noremap = true
})
-- Telescope
vim.api.nvim_set_keymap("n", "<leader>ff", ":Telescope find_files hidden=true<cr>", {
    noremap = true
})

vim.api.nvim_set_keymap("n", "<leader>fg", ":Telescope live_grep<cr>", {
    noremap = true
})

-- save/quit/other SETUPS
-- save
vim.api.nvim_set_keymap("n", "<C-s>", ":w<CR>", {
    noremap = true
})
-- quit
vim.api.nvim_set_keymap("n", "<C-q>", ":q<CR>", {
    noremap = true
})

-- BUFFERS 
vim.api.nvim_set_keymap("n", "<TAB>", ":Telescope buffers<CR>", {
    noremap = true
})

-- Commentary
vim.api.nvim_set_keymap("n", "<leader>/", "<Plug>kommentary_line_default", {})
vim.api.nvim_set_keymap("x", "<leader>c", "<Plug>kommentary_visual_default", {})
-- ALL SETUPS 

-- Setup nvimtree
require("nvim-tree").setup()

-- Status Line Setup
require('lualine').setup {
    options = {
        icons_enabled = true,
        theme = 'auto',
        component_separators = {
            left = '',
            right = ''
        },
        section_separators = {
            left = '',
            right = ''
        },
        disabled_filetypes = {
            statusline = {},
            winbar = {}
        },
        ignore_focus = {},
        always_divide_middle = true,
        globalstatus = false,
        refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000
        }
    },
    sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {'filename'},
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {'filename'},
        lualine_x = {'location'},
        lualine_y = {},
        lualine_z = {}
    },
    tabline = {},
    winbar = {},
    inactive_winbar = {},
    extensions = {}
}

-- Buffer Line
vim.opt.termguicolors = true
require("bufferline").setup {}

-- Prettier
local prettier = require("prettier")

prettier.setup({
    bin = 'prettier', -- or `'prettierd'` (v0.22+)
    filetypes = {"lua", "css", "graphql", "html", "javascript", "javascriptreact", "json", "less", "markdown", "scss",
                 "typescript", "typescriptreact", "yaml"}
})

-- Autopair
local npairs = require("nvim-autopairs")
local Rule = require('nvim-autopairs.rule')

npairs.setup({
    check_ts = true,
    ts_config = {
        lua = {'string'}, -- it will not add a pair on that treesitter node
        javascript = {'template_string'},
        java = false -- don't check treesitter on java
    }
})

local ts_conds = require('nvim-autopairs.ts-conds')

-- press % => %% only while inside a comment or string
npairs.add_rules({Rule("%", "%", "lua"):with_pair(ts_conds.is_ts_node({'string', 'comment'})),
                  Rule("$", "$", "lua"):with_pair(ts_conds.is_not_ts_node({'function'}))})
require("nvim-treesitter.configs").setup {
    highlight = {
        -- ...
    },
    -- ...
    rainbow = {
        enable = true,
        colors = {"#68a0b0", "#946EaD", "#c7aA6D" -- "Gold",
        -- "Orchid",
        -- "DodgerBlue",
        -- "Cornsilk",
        -- "Salmon",
        -- "LawnGreen",
        },
        disable = {}
    },
    enable = true,
    extended_mode = true
}

