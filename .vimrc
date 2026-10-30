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
" set termguicolors         " 24-bit colours (drop this if your terminal misrenders)
colorscheme slate

set expandtab           " Convert tabs to spaces
set tabstop=4           " 1 tab = 4 spaces
set shiftwidth=4        " Indent width
set autoindent          " Copy indent from current line on new line
set laststatus=2

set ignorecase
set smartcase
set incsearch

set scrolloff=16
set timeoutlen=2500

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

let g:fzf_layout = { 'down': '30%' }

" Move between windows with Ctrl-h/j/k/l
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Quicklist
nnoremap ]q :cnext<CR>
nnoremap [q :cprev<CR>
nnoremap ]Q :clast<CR>
nnoremap [Q :cfirst<CR>
nnoremap <leader>q :ccl

" LSP (vim-lsp)
set hidden                      " allow buffers to hide while LSP keeps them loaded
set completeopt=menu,menuone,noinsert,noselect

let g:lsp_hover_ui = 'preview' 
let g:lsp_diagnostics_echo_cursor = 1  " echo diagnostic under cursor
let g:lsp_diagnostics_virtual_text_enabled = 0  " no inline error text at end of lines
let g:lsp_semantic_enabled = 1
let g:lsp_log_verbose = 1
let g:lsp_log_file = expand('~/vim-lsp.log')
" let g:lsp_document_symbol_detail = 1

" gutter signs: E W I H by severity, A where a code action is available
let g:lsp_diagnostics_signs_error = {'text': 'E'}
let g:lsp_diagnostics_signs_warning = {'text': 'W'}
let g:lsp_diagnostics_signs_information = {'text': 'I'}
let g:lsp_diagnostics_signs_hint = {'text': 'H'}
let g:lsp_document_code_action_signs_hint = {'text': 'A'}

" TODO consider: let g:lsp_settings_filetype_python = 'pyright-langserver'  " use pyright for Python
let g:lsp_settings_filetype_rust = ['rust-analyzer']
let g:lsp_settings_filetype_markdown = 'markdown-oxide' 

" asyncomplete popup
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR> pumvisible() ? asyncomplete#close_popup() . "\<CR>" : "\<CR>"

" marksman path completion fix
"
" marksman returns link completions (e.g. in "[foo](./)") whose textEdit
" replaces the whole link, so vim-lsp/asyncomplete-lsp turn them into items
" like { word: '[foo](/b.md)', startcol: 1 }. asyncomplete's default matcher
" then fuzzy-matches the entire typed text ("[foo](./b") against that word:
" the typed '.' can never match before the '/', so every candidate is
" discarded and the popup stays empty. Instead, filter on the last segment
" typed (stopping at / ( [ # etc.) and match it against the candidate's
" actual target name (abbr, e.g. "b.md").
function! s:lsp_link_completion_filter(matches, startcol, base) abort
    let l:frag = matchstr(a:base, '[^/()\[\]#[:space:]]*$')
    let l:items = []
    let l:startcols = []
    for l:item in a:matches['items']
        let l:key = get(l:item, 'abbr', l:item['word'])
        if empty(l:frag) || !empty(matchfuzzy([l:key], l:frag))
            call add(l:items, l:item)
            call add(l:startcols, a:startcol)
        endif
    endfor
    return [l:items, l:startcols]
endfunction

function! s:patch_lsp_completion_filters() abort
    for l:name in asyncomplete#get_source_names()
        if l:name !=# 'asyncomplete_lsp_marksman'
            continue
        endif
        let l:info = asyncomplete#get_source_info(l:name)
        if !has_key(l:info, 'filter')
            let l:info['filter'] = function('s:lsp_link_completion_filter')
            call asyncomplete#register_source(l:info)
        endif
    endfor
endfunction

augroup lsp_marksman_completion_fix
    autocmd!
    " fires after asyncomplete-lsp registers the source (same event, later)
    autocmd User lsp_server_init call s:patch_lsp_completion_filters()
augroup END

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
    nmap <buffer> <leader>cn <plug>(lsp-rename)
    nmap <buffer> <leader>ca <plug>(lsp-code-action)
    nmap <buffer> [d <plug>(lsp-previous-diagnostic)
    nmap <buffer> ]d <plug>(lsp-next-diagnostic)
    nmap <buffer> <leader>fd :LspDocumentDiagnostics<CR>
    nmap <buffer> <leader>fs :LspDocumentSymbolSearch<CR>
    nmap <buffer> F :LspDocumentFormat<CR>


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

" Bracket matching colours: CursorMatch is the brace under the cursor, MatchParen
" its match. slate defines only MatchParen (yellow); CursorMatch is then left
" undefined and vim draws it as reverse video (the black block). Swapped here,
" and re-applied on ColorScheme so a theme switch cannot wipe them.
augroup my_highlight
  autocmd!
  autocmd ColorScheme *
        \ highlight CursorMatch cterm=bold ctermfg=16 ctermbg=220 guifg=#000000 guibg=#ffd700 |
        \ highlight MatchParen  cterm=bold ctermfg=220 ctermbg=16 guifg=#ffd700 guibg=#000000
augroup END

" ColorScheme already fired earlier in this file, so trigger it once by hand.
doautocmd ColorScheme

" HAMMERTIME
source ~/dev/hammertime/vimplugin.vim

" TODO
" Show git changes on the side?
" Setup opencode?
