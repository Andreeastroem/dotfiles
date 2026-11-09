set tabstop=2
set shiftwidth=2
set expandtab

filetype plugin indent on
syntax on

" --- Plugins (vim-plug) ---------------------------------------------------
call plug#begin()
Plug 'prabirshrestha/vim-lsp'              " language server client
Plug 'mattn/vim-lsp-settings'              " :LspInstallServer for any language
Plug 'prabirshrestha/asyncomplete.vim'     " completion popup
Plug 'prabirshrestha/asyncomplete-lsp.vim' " feeds LSP results into the popup
call plug#end()

" --- Completion ----------------------------------------------------------
set completeopt=menuone,noinsert,noselect
" Set to 0 to only show completions when you press Ctrl+Space
let g:asyncomplete_auto_popup = 1

" Ctrl+Space opens the completion menu (terminals send it as <C-@>)
imap <C-Space> <Plug>(asyncomplete_force_refresh)
imap <C-@>     <Plug>(asyncomplete_force_refresh)
" Tab / Shift-Tab to move through the menu, Enter to accept
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR>    pumvisible() ? asyncomplete#close_popup() : "\<CR>"

" --- LSP keys (active only in buffers with a language server) -------------
let g:lsp_diagnostics_echo_cursor = 1
" Keep the W>/E> signs but don't highlight the code itself

" Python: allow 2-space indents (E111/E114). The rest of the list is
" pycodestyle's default ignores, which would otherwise be replaced.
let g:lsp_settings = {
\  'pylsp-all': {
\    'workspace_config': {
\      'pylsp': {'plugins': {'pycodestyle': {'ignore': [
\        'E111', 'E114',
\        'E121', 'E123', 'E126', 'E226', 'E24', 'E704', 'W503', 'W504'
\      ]}, 'yapf': {'enabled': v:false}}}
\    }
\  }
\}
function! s:on_lsp_buffer_enabled() abort
  setlocal omnifunc=lsp#complete
  setlocal signcolumn=yes
  nmap <buffer> gd <plug>(lsp-definition)
  nmap <buffer> gr <plug>(lsp-references)
  nmap <buffer> K  <plug>(lsp-hover)
  nmap <buffer> <leader>rn <plug>(lsp-rename)
  nmap <buffer> [g <plug>(lsp-previous-diagnostic)
  nmap <buffer> ]g <plug>(lsp-next-diagnostic)
  nmap <buffer> <leader>f <plug>(lsp-document-format)
  " Auto-fix lint/style issues on save (Python: autopep8 via pylsp)
  augroup lsp_format_on_save
    autocmd! * <buffer>
    autocmd BufWritePre <buffer> LspDocumentFormatSync
  augroup END
endfunction
augroup lsp_install
  autocmd!
  autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END
