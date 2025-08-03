-- ~/.config/nvim/lua/keymaps.lua

local opts = { noremap = true, silent = true }

-- Variable global para mapeos de teclas
vim.g.mapleader = " "  -- Configura la tecla líder (leader key) a la barra espaciadora

-- Mapeos en modo normal
vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", opts) -- Abrir/cerrar explorador de archivos
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", opts)             -- Guardar archivo
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>", opts)             -- Salir de Neovim
vim.keymap.set("n", "<leader>s", "<cmd>wa<CR>", opts)            -- Guardar todos los archivos

-- Mover líneas arriba y abajo
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Búsqueda y reemplazo (usando la tecla líder)
vim.keymap.set("n", "<leader>/", "<cmd>IncSearch<CR>", opts) -- Buscar
