let g:loaded_youcompleteme = 1
let g:colorizer_startup = 0
set timeoutlen=300
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

" F2 cheatsheet (floating window)
nnoremap <F2> :lua require('cheatsheet').toggle()<CR>

lua << CHEATSHEET
local cheatsheet = {}
local win_id = nil

function cheatsheet.toggle()
  if win_id and vim.api.nvim_win_is_valid(win_id) then
    vim.api.nvim_win_close(win_id, true)
    win_id = nil
    return
  end
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = vim.fn.readfile(vim.fn.expand('~/.config/nvim/cheatsheet.txt'))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  local width = 58
  local height = #lines
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  win_id = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<F2>', ':lua require("cheatsheet").toggle()<CR>', {noremap=true, silent=true})
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':lua require("cheatsheet").toggle()<CR>', {noremap=true, silent=true})
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':lua require("cheatsheet").toggle()<CR>', {noremap=true, silent=true})
end

package.loaded['cheatsheet'] = cheatsheet
return cheatsheet
CHEATSHEET

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
