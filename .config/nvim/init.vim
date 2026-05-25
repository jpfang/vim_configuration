let g:loaded_youcompleteme = 1
let g:colorizer_startup = 0
let g:airline_powerline_fonts = 1
let g:loaded_nerdtree = 1
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1
let g:NERDTreeHijackNetrw = 0
source ~/.vimrc
silent! autocmd! NERDTreeHijackNetrw

call plug#begin('~/.local/share/nvim/plugged')
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', {'tag': '0.1.8'}
Plug 'goolord/alpha-nvim'
Plug 'nvim-tree/nvim-tree.lua'
Plug 'nvim-tree/nvim-web-devicons'
call plug#end()

" --- IDE keybindings ---
autocmd VimEnter * clearjumps

" Tab for completion
inoremap <silent><expr> <Tab> coc#pum#visible() ? coc#pum#confirm() : "\<Tab>"

nmap w <Plug>(coc-definition)
nmap q <C-o>
autocmd TabNew * clearjumps
nmap sw <Plug>(coc-references)
nmap gy <Plug>(coc-type-definition)
nmap gi <Plug>(coc-implementation)
nmap <leader>k :call CocActionAsync('doHover')<CR>
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
  pickers = {
    find_files = {
      mappings = {
        i = { ["<CR>"] = open_in_new_tab },
        n = { ["<CR>"] = open_in_new_tab },
      },
    },
    live_grep = {
      mappings = {
        i = { ["<CR>"] = open_in_new_tab },
        n = { ["<CR>"] = open_in_new_tab },
      },
    },
  },
}
EOF
nnoremap <leader>fs :CocList outline<CR>

" --- Alpha Dashboard ---
lua << ALPHA
-- nvim-tree setup
local function nvim_tree_on_attach(bufnr)
  local api = require('nvim-tree.api')
  api.config.mappings.default_on_attach(bufnr)
  vim.keymap.del('n', '<Tab>', {buffer = bufnr})
end
require('nvim-tree').setup({
  view = { width = 30 },
  renderer = { icons = { show = { file = true, folder = true, git = true } } },
  hijack_directories = { enable = true, auto_open = true },
  on_attach = nvim_tree_on_attach,
})
vim.keymap.set('n', '<F3>', ':NvimTreeToggle<CR>', {noremap=true, silent=true})

-- Open nvim-tree when opening a directory
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function(data)
    if vim.fn.isdirectory(data.file) == 1 then
      vim.cmd.cd(data.file)
      require('nvim-tree.api').tree.open()
    end
  end,
})

-- alpha dashboard
local alpha = require('alpha')
local dashboard = require('alpha.themes.dashboard')

dashboard.section.header.val = {
  "                                                     ",
  "  ███╗   ██╗██╗   ██╗██╗███╗   ███╗                 ",
  "  ████╗  ██║██║   ██║██║████╗ ████║                 ",
  "  ██╔██╗ ██║██║   ██║██║██╔████╔██║                 ",
  "  ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║                 ",
  "  ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║                 ",
  "  ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝                 ",
  "                                                     ",
}

dashboard.section.buttons.val = {
  dashboard.button("f", "  Find File",       ":Telescope find_files<CR>"),
  dashboard.button("w", "  Find Word",       ":Telescope live_grep<CR>"),
  dashboard.button("r", "  Recent Files",    ":Telescope oldfiles<CR>"),
  dashboard.button("e", "  File Browser",    ":NvimTreeToggle<CR>"),
  dashboard.button("c", "  Colorschemes",    ":Telescope colorscheme<CR>"),
  dashboard.button("n", "  New File",        ":enew<CR>"),
  dashboard.button("q", "  Quit",            ":qa<CR>"),
}

dashboard.section.footer.val = {
  "",
  "[ \\ff Find File | \\fg Grep | \\fb Buffers | F2 Cheatsheet | F3 NvimTree ]",
}

dashboard.config.opts.noautocmd = true
alpha.setup(dashboard.config)
ALPHA
