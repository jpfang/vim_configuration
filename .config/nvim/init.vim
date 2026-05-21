let g:loaded_youcompleteme = 1
source ~/.vimrc

call plug#begin('~/.local/share/nvim/plugged')
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', {'tag': '0.1.8'}
call plug#end()

" --- IDE keybindings ---
autocmd VimEnter * clearjumps

" Tab/Enter for completion
inoremap <silent><expr> <Tab> coc#pum#visible() ? coc#pum#next(1) : "\<Tab>"
inoremap <silent><expr> <S-Tab> coc#pum#visible() ? coc#pum#prev(1) : "\<S-Tab>"
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"

nmap w <Plug>(coc-definition)
nmap q <C-o>
autocmd TabNew * clearjumps
nmap sw <Plug>(coc-references)
nmap gy <Plug>(coc-type-definition)
nmap gi <Plug>(coc-implementation)
nmap K :call CocActionAsync('doHover')<CR>
nmap <leader>rn <Plug>(coc-rename)
nmap [d <Plug>(coc-diagnostic-prev)
nmap ]d <Plug>(coc-diagnostic-next)
nmap <leader>fm <Plug>(coc-format)

" Telescope
nnoremap <leader>ff :Telescope find_files<CR>
nnoremap <leader>fg :Telescope live_grep<CR>
nnoremap <leader>fb :Telescope buffers<CR>

lua << EOF
local actions = require('telescope.actions')
local function open_in_new_tab(prompt_bufnr)
  actions.select_tab(prompt_bufnr)
  vim.cmd('clearjumps')
end
require('telescope').setup{
  defaults = {
    mappings = {
      i = { ["<CR>"] = open_in_new_tab },
      n = { ["<CR>"] = open_in_new_tab },
    },
  },
}
EOF
nnoremap <leader>fs :CocList outline<CR>
