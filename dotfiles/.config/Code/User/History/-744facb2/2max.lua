-- ~/.config/nvim/lua/keymaps.lua

-- La tecla 'leader' es como un prefijo para tus propios atajos.
-- Por convención, se usa la barra espaciadora.
vim.g.mapleader = " "

local opts = { noremap = true, silent = true }

-- Mapeos en modo normal
--------------------------------------------------------------------------------
-- Navegación y búsqueda
vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", opts)  -- Abrir/cerrar explorador de archivos
vim.keymap.set("n", "<C-f>", "<cmd>Telescope find_files<CR>", opts)  -- Navegar archivos (similar a Ctrl+P en VS Code)
vim.keymap.set("n", "<C-b>", "<cmd>lua vim.fn.FzfLua 'files'<CR>", opts)  -- Otra forma de navegación de archivos
vim.keymap.set("n", "<C-q>", ":qa!<CR>", opts)  -- Cerrar Neovim forzadamente (sin guardar)

-- Gestión de ventanas/buffers (pestañas)
vim.keymap.set("n", "<C-w>", "<cmd>Bdelete<CR>", opts) -- Cerrar el buffer actual (similar a cerrar pestaña)
vim.keymap.set("n", "<C-Tab>", "<cmd>bnext<CR>", opts) -- Navegar a la siguiente pestaña
vim.keymap.set("n", "<C-S-Tab>", "<cmd>bprevious<CR>", opts) -- Navegar a la pestaña anterior

-- Guardar y salir
vim.keymap.set("n", "<C-s>", ":w<CR>", opts) -- Guardar archivo
vim.keymap.set("n", "<C-q>", ":q<CR>", opts)  -- Cerrar Neovim (con advertencia si no se guardó)


-- Mapeos en modo visual
--------------------------------------------------------------------------------
-- Duplicar líneas
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", opts) -- Mover selección abajo
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", opts) -- Mover selección arriba

-- Copiar, cortar y pegar
vim.keymap.set("v", "<C-c>", '"+y', opts)  -- Copiar al portapapeles del sistema
vim.keymap.set("v", "<C-x>", '"+x', opts)  -- Cortar al portapapeles del sistema
vim.keymap.set("n", "<C-v>", '"+P', opts)  -- Pegar desde el portapapeles del sistema (modo normal)
vim.keymap.set("v", "<C-v>", '"+P', opts)  -- Pegar desde el portapapeles del sistema (modo visual)

-- Mapeos en modo de inserción
--------------------------------------------------------------------------------
-- Copiar y pegar
vim.keymap.set("i", "<C-v>", "<C-r>+", opts)  -- Pegar desde el portapapeles del sistema
