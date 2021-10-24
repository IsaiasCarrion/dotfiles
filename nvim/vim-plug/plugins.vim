call plug#begin('~/.config/nvim/plugged')
    " Comment code
    Plug 'tpope/vim-commentary'

    if exists('g:vscode')
        " Easy motion for VSCode
        Plug 'asvetliakov/vim-easymotion'
    else
        " Syntax support
        Plug 'sheerun/vim-polyglot'
        Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
        Plug 'mattn/emmet-vim'
        
        " Autopairs
        Plug 'jiangmiao/auto-pairs'
        
        " File explorer
        Plug 'scrooloose/NERDTree'    
        
        " Icons
        Plug 'ryanoasis/vim-devicons'
        
        " Intellisense
        Plug 'neoclide/coc.nvim', {'branch': 'release'}
        
        " Airline
        Plug 'vim-airline/vim-airline'
        Plug 'vim-airline/vim-airline-themes'
        " Indent guides
        " Plug 'Yggdroot/indentLine' 
        
        " Git integration
        Plug 'mhinz/vim-signify'
        " Git commands within vim
        Plug 'tpope/vim-fugitive'
        " Git changes on the gutter
        Plug 'airblade/vim-gitgutter'
        " Nerdtree git changes
        Plug 'Xuyuanp/nerdtree-git-plugin'
        
        " Autoclose tags
        Plug 'alvan/vim-closetag'
        
        " Ranger
        Plug 'kevinhwang91/rnvimr', {'do': 'make sync'}
        
        " Fzf
        Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
        Plug 'junegunn/fzf.vim'
        Plug 'airblade/vim-rooter'
        
        " Prettier
        Plug 'prettier/vim-prettier', { 'do': 'yarn install' }
        " Rainbow Brackets
        Plug 'luochen1990/rainbow'

        " Themes
        Plug 'joshdick/onedark.vim'
        Plug 'kaicataldo/material.vim'
        Plug 'tomasiser/vim-code-dark'
        Plug 'crusoexia/vim-monokai'
        Plug 'ayu-theme/ayu-vim'
        Plug 'dracula/vim', { 'as': 'dracula' }
        Plug 'phanviet/vim-monokai-pro'
		Plug 'morhetz/gruvbox'
    endif
call plug#end()
