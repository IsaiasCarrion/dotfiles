-- ~/.config/nvim/init.lua

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Aquí vamos a cargar nuestros plugins y la configuración principal
-- Por ahora, solo cargaremos los plugins
require("plugins")

-- Opciones de Neovim
vim.opt.nu = true -- Muestra los números de línea
vim.opt.relativenumber = true -- Muestra los números de línea relativos
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true
