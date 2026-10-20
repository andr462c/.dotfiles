" When started as "evim", evim.vim will already have done these settings, bail
" out.
if v:progname =~? "evim"
  finish
endif

" Get the defaults that most users want.
source $VIMRUNTIME/defaults.vim

if has("vms")
  set nobackup		" do not keep a backup file, use versions instead
else
  set backup		" keep a backup file (restore to previous version)
  if has('persistent_undo')
    set undofile	" keep an undo file (undo changes after closing)
  endif
endif

" Keep backup and undo files out of project directories
set backupdir=~/.vim/backup//
set undodir=~/.vim/undo//

if &t_Co > 2 || has("gui_running")
  " Switch on highlighting the last used search pattern.
  set hlsearch
endif

" Put these in an autocmd group, so that we can delete them easily.
augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 78 characters.
  autocmd FileType text setlocal textwidth=78
augroup END

" Add optional packages.
"
" The matchit plugin makes the % command work better, but it is not backwards
" compatible.
" The ! means the package won't be loaded right away but when plugins are
" loaded during initialization.
if has('syntax') && has('eval')
  packadd! matchit
  packadd! comment      " gcc / gc{motion} / visual gc to toggle comments
endif

" General settings
set number
set signcolumn=yes        " always reserve the gutter, so LSP signs don't shift the text
set mouse=a
set clipboard=unnamedplus
set termguicolors         " 24-bit colours (drop this if your terminal misrenders)
colorscheme slate

set expandtab           " Convert tabs to spaces
set tabstop=4           " 1 tab = 4 spaces
set shiftwidth=4        " Indent width
set autoindent          " Copy indent from current line on new line

set ignorecase
set smartcase
set incsearch

set scrolloff=8

" Show a list of available autocompletions instead of selecting the first
set wildmenu
set wildmode=longest:list

" Plugins
call plug#begin()
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
call plug#end()

" Keymaps
" fzf.vim
nnoremap <leader>ff :Files<CR>
nnoremap <leader>fg :GFiles<CR>
nnoremap <leader>fh :History<CR>
nnoremap <leader>fl :Lines<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>g :Rg<CR>

" Move between windows with Ctrl-h/j/k/l
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" LSP (vim-lsp)
set hidden                      " allow buffers to hide while LSP keeps them loaded
set completeopt=menu,menuone,noinsert,noselect

let g:lsp_hover_ui = 'preview' 
let g:lsp_diagnostics_echo_cursor = 1  " echo diagnostic under cursor
let g:lsp_diagnostics_virtual_text_enabled = 0  " no inline error text at end of lines
let g:lsp_semantic_enabled = 1

" vim-lsp only maps the standard LSP token types; rust-analyzer sends ~58 and
" the rest would fall back to Normal. Map them explicitly (must come after the
" colorscheme, which clears highlights, so vim-lsp leaves them alone).
highlight link LspSemanticBuiltinType      Type
highlight link LspSemanticSelfTypeKeyword  Type
highlight link LspSemanticTypeAlias        Type
highlight link LspSemanticConstParameter   Type
highlight link LspSemanticSelfKeyword      Keyword
highlight link LspSemanticLifetime         Identifier
highlight link LspSemanticMacroBang        Macro
highlight link LspSemanticProcMacro        Macro
highlight link LspSemanticAttribute        PreProc
highlight link LspSemanticDerive           PreProc
highlight link LspSemanticBoolean          Constant
highlight link LspSemanticNumber           Number
highlight link LspSemanticFormatSpecifier  Special
highlight link LspSemanticEscapeSequence   Special
highlight link LspSemanticStatic           Constant
highlight link LspSemanticUnresolvedReference Error

" gutter signs: E W I H by severity, A where a code action is available
let g:lsp_diagnostics_signs_error = {'text': 'E'}
let g:lsp_diagnostics_signs_warning = {'text': 'W'}
let g:lsp_diagnostics_signs_information = {'text': 'I'}
let g:lsp_diagnostics_signs_hint = {'text': 'H'}
let g:lsp_document_code_action_signs_hint = {'text': 'A'}

" TODO consider: let g:lsp_settings_filetype_python = 'pyright-langserver'  " use pyright for Python
let g:lsp_settings_filetype_rust = 'rust-analyzer' 

" asyncomplete popup
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR> pumvisible() ? asyncomplete#close_popup() . "\<CR>" : "\<CR>"

augroup lsp_install
  au!
  " set keymaps when an LSP server attaches
  autocmd User lsp_buffer_enabled call s:lsp_setup()
augroup END

" LSP keymaps (normal mode, only in buffers with an LSP server)
function! s:lsp_setup()
  nmap <buffer> gd <plug>(lsp-definition)
  nmap <buffer> <silent> gr <plug>(lsp-references)
  nmap <buffer> K <plug>(lsp-hover)
  nmap <buffer> <leader>rn <plug>(lsp-rename)
  nmap <buffer> <leader>ca <plug>(lsp-code-action)
  nmap <buffer> [d <plug>(lsp-previous-diagnostic)
  nmap <buffer> ]d <plug>(lsp-next-diagnostic)

  " Ctrl-d/Ctrl-u scroll the hover popup while it's open
  nnoremap <buffer> <expr> <C-d> <SID>popup_scroll(+4, "\<C-d>")
  nnoremap <buffer> <expr> <C-u> <SID>popup_scroll(-4, "\<C-u>")
endfunction

" Scroll the LSP hover popup if it's open, otherwise do the key's normal job
function! s:popup_scroll(count, key) abort
  let l:id = lsp#document_hover_preview_winid()
  if !empty(l:id) && !empty(popup_getpos(l:id))
    return lsp#scroll(a:count)
  endif
  return a:key
endfunction

" TODO
" Show git changes on the side?
" Search for treesiter symboles?
" More colors?
