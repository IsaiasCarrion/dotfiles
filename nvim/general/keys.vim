" Remap escape
nnoremap <C-c> <Esc>
inoremap jk <Esc>
inoremap kj <Esc>
inoremap jj <Esc>
inoremap kk <Esc>

" Use alt + hjkl to resize windows
nnoremap <M-j> :resize -2<CR>
nnoremap <M-k> :resize +2<CR>
nnoremap <M-h> :vertical resize -2<CR>
nnoremap <M-l> :vertical resize +2<CR>

" Alternate way to save
nnoremap <C-s> :w<CR>
" Alternate way to quit and save
nnoremap <C-q> :wq!<CR>

" Close current buffer
nnoremap <C-b> :bd<CR>

" Better tabbing
vnoremap < <gv
vnoremap > >gv

" Move selected line / block of text in visual mode
" shift + k to move up
" shift + j to move down
xnoremap K :move '<-2<CR>gv-gv
xnoremap J :move '>+1<CR>gv-gv

" Better window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Term

augroup exe_code
    autocmd!
    
    "execute python code"
    autocmd FileType python nnoremap <buffer> <F5>
        \ :sp<CR> :term python3 %<CR> :startinsert<CR>
    
    "execute Javascript code"
    autocmd FileType javascript nnoremap <buffer> <F5>
        \ :sp<CR> :term node %<CR> :startinsert<CR>
    
    "execute bash code"
    autocmd FileType bash,sh nnoremap <buffer> <F5>
        \ :sp<CR> :term bash %<CR> :startinsert<CR>

augroup END

if !exists('g:vscode')
    " TAB in general mode will move to next buffer
    nnoremap <TAB> :bnext<CR>
    " SHIFT-TAB will go to prev buffer
    nnoremap <S-TAB> :bprevious<CR>
endif
