let g:loaded_youcompleteme = 1
let g:colorizer_startup = 0
let g:airline_powerline_fonts = 1
let g:loaded_nerdtree = 1
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1
let g:NERDTreeHijackNetrw = 0
source ~/.vimrc
silent! autocmd! NERDTreeHijackNetrw

let g:coc_node_path = trim(system('bash -c "source ~/.nvm/nvm.sh && nvm which 20"'))

call plug#begin('~/.local/share/nvim/plugged')
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', {'tag': '0.1.8'}
Plug 'goolord/alpha-nvim'
Plug 'nvim-tree/nvim-tree.lua'
Plug 'nvim-tree/nvim-web-devicons'
Plug 'tpope/vim-fugitive'
Plug 'lewis6991/gitsigns.nvim'
call plug#end()

" --- IDE keybindings ---
autocmd VimEnter * clearjumps

" Tab for completion
inoremap <silent><expr> <Tab> coc#pum#visible() ? coc#pum#confirm() : "\<Tab>"

nnoremap < :tabp<CR>
nnoremap > :tabn<CR>
lua << NAVSTACK
-- Custom navigation stack (push on jump, pop on q)
_G._nav_stack = {}

-- Custom entry maker for telescope-coc: show only filename:lnum
_G._coc_loc_entry_maker = function(entry)
  local filename = vim.fn.fnamemodify(entry.filename or '', ':~:.')
  local display = filename .. ':' .. entry.lnum
  return {
    value = entry,
    display = display,
    ordinal = display,
    filename = entry.filename,
    lnum = entry.lnum,
    col = entry.col,
  }
end

-- Telescope picker for coc locations (references, definitions, etc.)
_G._coc_telescope = function(action, title, provider)
  if vim.fn.CocHasProvider(provider) == 0 then
    print('Coc: server does not support ' .. provider)
    return
  end
  vim.fn.CocActionAsync(action, function(err, locs)
    if err ~= vim.NIL or type(locs) ~= 'table' or vim.tbl_isempty(locs) then return end
    vim.schedule(function()
      local items = {}
      for _, l in ipairs(locs) do
        if l.targetUri then l.uri = l.targetUri; l.range = l.targetRange end
        local filename = vim.uri_to_fname(l.uri)
        items[#items + 1] = {
          filename = filename,
          lnum = l.range.start.line + 1,
          col = l.range.start.character + 1,
        }
      end
      if #items == 1 and action ~= 'references' then
        vim.cmd('edit ' .. vim.fn.fnameescape(items[1].filename))
        vim.api.nvim_win_set_cursor(0, {items[1].lnum, items[1].col - 1})
        return
      end
      local conf = require('telescope.config').values
      require('telescope.pickers').new({}, {
        prompt_title = title,
        previewer = conf.qflist_previewer({}),
        sorter = conf.generic_sorter({}),
        finder = require('telescope.finders').new_table({
          results = items,
          entry_maker = _G._coc_loc_entry_maker,
        }),
      }):find()
    end)
  end)
end

local function get_tab_stack()
  local tab = vim.api.nvim_get_current_tabpage()
  if not _G._nav_stack[tab] then
    _G._nav_stack[tab] = {}
  end
  return _G._nav_stack[tab]
end

local function push_if_different(stack, buf, pos)
  local top = stack[#stack]
  if top and top.buf == buf and top.pos[1] == pos[1] then
    return
  end
  table.insert(stack, { buf = buf, pos = pos })
end

-- Push current position before jumping to definition
vim.keymap.set('n', 'w', function()
  if vim.bo.filetype == 'fugitiveblame' or vim.bo.filetype == 'NvimTree' or vim.bo.filetype == 'tagbar' or vim.bo.buftype ~= '' then return end
  local stack = get_tab_stack()
  local buf = vim.api.nvim_get_current_buf()
  local pos = vim.api.nvim_win_get_cursor(0)
  push_if_different(stack, buf, pos)
  _G._coc_telescope('definitions', 'Definitions', 'definition')
end, {noremap = true, silent = true})

-- Pop: go back to previous position
vim.keymap.set('n', 'q', function()
  local bt = vim.bo.buftype
  if bt == 'quickfix' or bt == 'prompt' then return end
  if vim.bo.filetype == 'tagbar' then vim.cmd('TagbarClose') return end
  local stack = get_tab_stack()
  if #stack == 0 then return end
  local entry = table.remove(stack)
  if not vim.api.nvim_buf_is_valid(entry.buf) then return end
  -- Close coc list/preview windows
  if vim.wo.winfixbuf or bt ~= '' then
    local cur_win = vim.api.nvim_get_current_win()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_is_valid(win) and win ~= cur_win then
        local wbuf = vim.api.nvim_win_get_buf(win)
        local wbt = vim.bo[wbuf].buftype
        if wbt ~= '' or vim.wo[win].winfixbuf then
          vim.api.nvim_win_close(win, true)
        end
      end
    end
    -- Close current window too if it's a special window
    if vim.api.nvim_win_is_valid(cur_win) and (vim.wo[cur_win].winfixbuf or bt ~= '') then
      local wins = vim.api.nvim_tabpage_list_wins(0)
      if #wins > 1 then
        vim.api.nvim_win_close(cur_win, true)
      end
    end
  end
  if vim.api.nvim_get_current_buf() ~= entry.buf then
    vim.api.nvim_set_current_buf(entry.buf)
  end
  vim.api.nvim_win_set_cursor(0, entry.pos)
end, {noremap = true, silent = true})

-- Show navigation stack with preview
vim.keymap.set('n', 'ss', function()
  if vim.bo.buftype ~= '' then return end
  -- temporarily disable cursorbind to avoid cursor jump (skip blame window)
  local saved_cursorbind = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype ~= 'fugitiveblame' then
      saved_cursorbind[win] = vim.wo[win].cursorbind
      vim.wo[win].cursorbind = false
    end
  end
  local function restore_cursorbind()
    for win, val in pairs(saved_cursorbind) do
      if vim.api.nvim_win_is_valid(win) then
        vim.wo[win].cursorbind = val
      end
    end
  end
  local stack = get_tab_stack()
  if #stack == 0 then
    print('[nav] stack is empty')
    restore_cursorbind()
    return
  end
  local lines = {}
  for i = #stack, 1, -1 do
    local e = stack[i]
    local name = vim.api.nvim_buf_is_valid(e.buf) and vim.api.nvim_buf_get_name(e.buf) or '[invalid]'
    table.insert(lines, string.format(' %d  %s:%d', #stack - i + 1, vim.fn.fnamemodify(name, ':~:.'), e.pos[1]))
  end

  local width = math.floor(vim.o.columns * 0.8)
  local total_height = math.floor(vim.o.lines * 0.8)
  local list_height = math.min(#lines, math.floor(total_height * 0.3))
  local preview_height = total_height - list_height - 2
  local start_col = math.floor((vim.o.columns - width) / 2)
  local start_row = math.floor((vim.o.lines - total_height) / 2)

  local preview_buf = vim.api.nvim_create_buf(false, true)
  local preview_win = vim.api.nvim_open_win(preview_buf, false, {
    relative = 'editor',
    width = width,
    height = preview_height,
    row = start_row,
    col = start_col,
    style = 'minimal',
    border = 'rounded',
    title = ' Preview ',
  })

  local list_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, lines)
  vim.bo[list_buf].modifiable = false

  local list_win = vim.api.nvim_open_win(list_buf, true, {
    relative = 'editor',
    width = width,
    height = list_height,
    row = start_row + preview_height + 2,
    col = start_col,
    style = 'minimal',
    border = 'rounded',
    title = ' Nav Stack ',
  })

  local function update_preview()
    local cursor = vim.api.nvim_win_get_cursor(list_win)[1]
    local idx = #stack - cursor + 1
    local e = stack[idx]
    if not e or not vim.api.nvim_buf_is_valid(e.buf) then return end
    local total = vim.api.nvim_buf_line_count(e.buf)
    local start = math.max(0, e.pos[1] - math.floor(preview_height / 2))
    local end_l = math.min(total, start + preview_height)
    local preview_lines = vim.api.nvim_buf_get_lines(e.buf, start, end_l, false)
    vim.bo[preview_buf].modifiable = true
    vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, preview_lines)
    vim.bo[preview_buf].modifiable = false
    local ft = vim.bo[e.buf].filetype
    if ft and ft ~= '' then
      vim.bo[preview_buf].filetype = ft
    end
    vim.api.nvim_buf_clear_namespace(preview_buf, -1, 0, -1)
    local hl_line = e.pos[1] - start - 1
    if hl_line >= 0 and hl_line < #preview_lines then
      vim.api.nvim_buf_add_highlight(preview_buf, -1, 'Visual', hl_line, 0, -1)
    end
  end

  update_preview()

  vim.api.nvim_create_autocmd('CursorMoved', {
    buffer = list_buf,
    callback = function()
      if vim.api.nvim_win_is_valid(preview_win) then update_preview() end
    end,
  })

  local function close()
    local cur_win = vim.api.nvim_get_current_win()
    local cur_pos = (cur_win ~= list_win and cur_win ~= preview_win) and vim.api.nvim_win_get_cursor(cur_win) or nil
    if vim.api.nvim_win_is_valid(preview_win) then vim.api.nvim_win_close(preview_win, true) end
    if vim.api.nvim_win_is_valid(list_win) then vim.api.nvim_win_close(list_win, true) end
    if cur_pos and vim.api.nvim_win_is_valid(cur_win) then
      pcall(vim.api.nvim_win_set_cursor, cur_win, cur_pos)
    end
    restore_cursorbind()
  end

  local function jump()
    local cursor = vim.api.nvim_win_get_cursor(list_win)[1]
    local idx = #stack - cursor + 1
    local e = stack[idx]
    close()
    if e and vim.api.nvim_buf_is_valid(e.buf) then
      vim.api.nvim_set_current_buf(e.buf)
      vim.api.nvim_win_set_cursor(0, e.pos)
      for _ = 1, (#stack - idx + 1) do table.remove(stack) end
    end
  end

  vim.keymap.set('n', '<CR>', jump, {buffer = list_buf, noremap = true, silent = true})
  vim.keymap.set('n', 'ss', close, {buffer = list_buf, noremap = true, silent = true})
  vim.keymap.set('n', 'q', close, {buffer = list_buf, noremap = true, silent = true})
  vim.keymap.set('n', '<Esc>', close, {buffer = list_buf, noremap = true, silent = true})
end, {noremap = true, silent = true})

-- Push current position before jumping to references
vim.keymap.set('n', 'sw', function()
  local buf = vim.api.nvim_get_current_buf()
  local pos = vim.api.nvim_win_get_cursor(0)
  if vim.bo.buftype == '' and not vim.wo.winfixbuf then
    local stack = get_tab_stack()
    push_if_different(stack, buf, pos)
  end
  _G._coc_telescope('references', 'References', 'reference')
end, {noremap = true, silent = true})

vim.keymap.set('n', 'sd', function()
  local stack = get_tab_stack()
  push_if_different(stack, vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(0))
  _G._coc_telescope('typeDefinitions', 'Type Definitions', 'typeDefinition')
end, {noremap = true, silent = true})

vim.keymap.set('n', 'si', function()
  local stack = get_tab_stack()
  push_if_different(stack, vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(0))
  _G._coc_telescope('implementations', 'Implementations', 'implementation')
end, {noremap = true, silent = true})
NAVSTACK
lua << HOVER_JUMP
vim.keymap.set('n', '<leader>d', function()
  vim.fn.CocActionAsync('doHover')
  vim.api.nvim_create_autocmd('User', {
    pattern = 'CocOpenFloat',
    once = true,
    callback = function()
      vim.schedule(function()
        vim.fn['coc#float#jump']()
        local buf = vim.api.nvim_get_current_buf()
        vim.keymap.set('n', '<Esc>', function() vim.fn['coc#float#close_all']() end, {buffer = buf, noremap = true, silent = true})
        vim.keymap.set('n', 'q', '<Nop>', {buffer = buf, noremap = true, silent = true})
        vim.keymap.set('n', 'w', '<Nop>', {buffer = buf, noremap = true, silent = true})
        vim.keymap.set('n', 'ss', '<Nop>', {buffer = buf, noremap = true, silent = true})
      end)
    end,
  })
end, {noremap = true, silent = true})
HOVER_JUMP
nmap <leader>rn <Plug>(coc-rename)
nmap [d <Plug>(coc-diagnostic-prev)
nmap ]d <Plug>(coc-diagnostic-next)
nmap <leader>fm <Plug>(coc-format)
vmap <leader>fm <Plug>(coc-format-selected)

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
vnoremap <leader>fg "zy:Telescope live_grep default_text=<C-r>z<CR>
nnoremap <leader>fb :Telescope buffers<CR>
nnoremap <leader>fr :Telescope oldfiles<CR>

lua << EOF
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local function open_in_new_tab(prompt_bufnr)
  local entry = action_state.get_selected_entry()
  if not entry then return end
  local path = entry.path or entry.filename
  if not path then return end
  actions.close(prompt_bufnr)
  vim.schedule(function()
    -- If current buffer is dashboard or empty, open in same tab
    if vim.bo.filetype == 'alpha' or vim.fn.bufname() == '' or vim.bo.buftype == 'nofile' then
      vim.cmd('edit ' .. vim.fn.fnameescape(path))
    else
      vim.cmd('tabedit ' .. vim.fn.fnameescape(path))
    end
    if entry.lnum then vim.cmd(tostring(entry.lnum)) end
    vim.cmd('clearjumps')
  end)
end

-- Save buffer before telescope opens
vim.api.nvim_create_autocmd('User', {
  pattern = 'TelescopeFindPre',
  callback = function()
    orig_buf = vim.api.nvim_get_current_buf()
  end,
})

require('telescope').setup{
  defaults = {
    layout_strategy = 'vertical',
    layout_config = {
      vertical = {
        preview_cutoff = 0,
        prompt_position = 'bottom',
        mirror = false,
      },
    },
    cycle_layout_list = {},
    scroll_strategy = 'limit',
    mappings = {
      i = {
        ["<C-j>"] = require('telescope.actions').preview_scrolling_down,
        ["<C-k>"] = require('telescope.actions').preview_scrolling_up,
      },
      n = {
        ["<C-j>"] = require('telescope.actions').preview_scrolling_down,
        ["<C-k>"] = require('telescope.actions').preview_scrolling_up,
      },
    },
  },
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
  vim.keymap.set('n', 'q', ':NvimTreeClose<CR>', {buffer = bufnr, noremap = true, silent = true})
  -- Open file in new tab without affecting original tab's jumplist
  vim.keymap.set('n', '<CR>', function()
    local node = api.tree.get_node_under_cursor()
    if not node or node.type == 'directory' then
      api.node.open.edit()
      return
    end
    vim.cmd('NvimTreeClose')
    vim.cmd('tabnew ' .. vim.fn.fnameescape(node.absolute_path))
    vim.cmd('clearjumps')
  end, {buffer = bufnr, noremap = true, silent = true})
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

-- alpha dashboard with cat chasing ball animation
local alpha = require('alpha')
local dashboard = require('alpha.themes.dashboard')

local logo = {
  "                                                     ",
  "  ███╗   ██╗██╗   ██╗██╗███╗   ███╗  ",
  "  ████╗  ██║██║   ██║██║████╗ ████║  ",
  "  ██╔██╗ ██║██║   ██║██║██╔████╔██║  ",
  "  ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║  ",
  "  ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║  ",
  "  ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝  ",
  "                                                     ",
}

math.randomseed(os.time())
local width = vim.o.columns
local field_height = 16
local logo_width = vim.fn.strdisplaywidth(logo[2])
local logo_left = math.floor((width - logo_width) / 2)
local logo_right = logo_left + logo_width
local logo_top = math.floor((field_height - #logo) / 2) + 1
local logo_bot = logo_top + #logo - 1

-- Ball state
local function is_logo(r, c)
  if r >= logo_top and r <= logo_bot and c >= logo_left and c <= logo_right then
    return true
  end
  return false
end

local function random_pos_outside_logo()
  local x, y
  repeat
    x = math.random(5, width - 5)
    y = math.random(3, field_height - 3)
  until not is_logo(y, x)
  return x, y
end

local bx, by = random_pos_outside_logo()
local ball = { x = bx, y = by, dx = 1, dy = 1, speed = 3, tick = 0 }
-- Cat state
local cx, cy = random_pos_outside_logo()
local cat = { x = cx, y = cy, pause = 0, throw_dir = 1, throw_count = 0, sleeping = false, idle_ticks = 0 }

local function move_ball()
  -- Ball moves only when tick reaches threshold (lower speed = slower)
  ball.tick = ball.tick + 1
  if ball.tick < (4 - ball.speed) then return end
  ball.tick = 0

  -- Decelerate over time
  if ball.speed > 1 then
    ball.speed = ball.speed - 0.05
    if ball.speed < 1 then ball.speed = 1 end
  end

  local nx = ball.x + ball.dx
  local ny = ball.y + ball.dy

  -- Bounce off walls
  if nx < 3 or nx > width - 3 then ball.dx = -ball.dx; nx = ball.x + ball.dx end
  if ny < 3 or ny > field_height - 2 then ball.dy = -ball.dy; ny = ball.y + ball.dy end

  -- Bounce off logo
  if is_logo(ny, nx) then
    ball.dx = -ball.dx
    ball.dy = -ball.dy
    -- Add horizontal offset to prevent ball staying directly above/below logo
    if nx >= logo_left and nx <= logo_right then
      ball.dx = (nx < logo_left + math.floor((logo_right - logo_left) / 2)) and -1 or 1
    end
    nx = ball.x + ball.dx
    ny = ball.y + ball.dy
  end

  -- Cat catches ball - bounce away from cat and accelerate
  if not cat.sleeping and math.abs(nx - cat.x) <= 2 and math.abs(ny - cat.y) <= 2 then
    -- Same direction for 3 throws, then random
    cat.throw_count = cat.throw_count + 1
    if cat.throw_count > 3 then
      cat.throw_dir = math.random() > 0.5 and 1 or -1
      cat.throw_count = 1
    end
    ball.dx = cat.throw_dir
    ball.dy = math.random() > 0.5 and 1 or -1
    ball.speed = 3
    cat.pause = 5
    -- Push ball further away
    nx = ball.x + ball.dx * 15
    ny = ball.y + ball.dy * 15
  end

  ball.x = math.max(3, math.min(width - 3, nx))
  ball.y = math.max(3, math.min(field_height - 2, ny))
end

local function move_cat()
  -- Cat pauses after hitting ball
  if cat.pause > 0 then
    cat.pause = cat.pause - 1
    return
  end

  local dx = 0
  local dy = 0
  if ball.x > cat.x then dx = 1 elseif ball.x < cat.x then dx = -1 end
  if ball.y > cat.y then dy = 1 elseif ball.y < cat.y then dy = -1 end

  local nx = cat.x + dx
  local ny = cat.y + dy

  -- Keep within bounds
  nx = math.max(4, math.min(width - 4, nx))
  ny = math.max(3, math.min(field_height - 2, ny))

  -- Check if direct path is blocked by logo
  local blocked = is_logo(ny, nx) and is_logo(cat.y, nx) and is_logo(ny, cat.x)

  if not blocked then
    if not is_logo(ny, nx) then
      cat.x = nx
      cat.y = ny
    elseif not is_logo(cat.y, nx) then
      cat.x = nx
    elseif not is_logo(ny, cat.x) then
      cat.y = ny
    end
  else
    -- Navigate around logo: move to nearest side edge
    local go_left = (cat.x <= logo_left + math.floor((logo_right - logo_left) / 2))
    local target_x = go_left and (logo_left - 2) or (logo_right + 2)
    target_x = math.max(4, math.min(width - 4, target_x))

    if cat.x ~= target_x then
      cat.x = cat.x + (target_x > cat.x and 1 or -1)
    else
      -- Reached the side, now move vertically toward ball
      local new_y = cat.y + dy
      new_y = math.max(3, math.min(field_height - 2, new_y))
      cat.y = new_y
    end
  end
end

local function build_header()
  -- Build field with static background
  local grid = {}
  for r = 1, field_height do
    grid[r] = {}
    for c = 1, width do
      -- Ground with grass
      if r == field_height then
        if c % 4 == 1 then grid[r][c] = ","
        elseif c % 7 == 3 then grid[r][c] = "'"
        else grid[r][c] = "_" end
      elseif r == field_height - 1 then
        if c % 11 == 1 then grid[r][c] = "."
        else grid[r][c] = " " end
      else
        grid[r][c] = " "
      end
    end
  end

  -- Scattered dots for sky texture
  if width > 20 then
    grid[1][5] = "."
    grid[2][width - 8] = "."
    grid[1][width - 20] = "*"
    grid[3][12] = "."
    grid[2][math.floor(width / 2) + 10] = "."
  end

  -- Place logo
  for i, l in ipairs(logo) do
    local r = logo_top + i - 1
    if r >= 1 and r <= field_height then
      local col = logo_left + 1
      for c = 0, vim.fn.strchars(l) - 1 do
        local ch = vim.fn.strcharpart(l, c, 1)
        if col >= 1 and col <= width then
          grid[r][col] = ch
        end
        col = col + 1
      end
    end
  end

  -- Place cat (7x5)
  local cx, cy = cat.x, cat.y
  local function put(r, c, ch)
    if r >= 1 and r <= field_height and c >= 1 and c <= width then
      grid[r][c] = ch
    end
  end

  local dist = math.abs(ball.x - cat.x) + math.abs(ball.y - cat.y)
  local pose = "normal"
  if cat.sleeping then
    pose = "sleep"
  elseif cat.pause > 0 then
    pose = "throw"
  elseif dist > 20 then
    pose = "run"
  elseif dist < 6 then
    pose = "crouch"
  end

  if pose == "sleep" then
    -- Sleeping pose (curled into ball)
    if cat.idle_ticks % 4 < 2 then
      put(cy - 2, cx + 2, "z")
      put(cy - 3, cx + 3, "Z")
    else
      put(cy - 2, cx + 2, "Z")
      put(cy - 3, cx + 3, "z")
    end
    put(cy - 1, cx - 2, "/")
    put(cy - 1, cx - 1, "\\")
    put(cy - 1, cx, "_")
    put(cy - 1, cx + 1, "/")
    put(cy - 1, cx + 2, "\\")
    put(cy, cx - 3, "(")
    put(cy, cx - 2, " ")
    put(cy, cx - 1, "-")
    put(cy, cx, ".")
    put(cy, cx + 1, "-")
    put(cy, cx + 2, " ")
    put(cy, cx + 3, ")")
    put(cy, cx + 4, "~")
    put(cy, cx + 5, "~")
    put(cy + 1, cx - 2, "\\")
    put(cy + 1, cx - 1, "_")
    put(cy + 1, cx, "_")
    put(cy + 1, cx + 1, "_")
    put(cy + 1, cx + 2, "_")
    put(cy + 1, cx + 3, "/")
  elseif pose == "throw" then
    -- Throwing pose (direction aware)
    put(cy - 2, cx - 2, "/")
    put(cy - 2, cx - 1, "\\")
    put(cy - 2, cx + 1, "/")
    put(cy - 2, cx + 2, "\\")
    if cat.throw_dir > 0 then
      put(cy - 1, cx - 3, "(")
      put(cy - 1, cx - 2, " ")
      put(cy - 1, cx - 1, " ")
      put(cy - 1, cx, ".")
      put(cy - 1, cx + 1, ">")
      put(cy - 1, cx + 2, " ")
      put(cy - 1, cx + 3, ")")
      put(cy, cx - 3, "(")
      put(cy, cx - 2, " ")
      put(cy, cx - 1, " ")
      put(cy, cx, " ")
      put(cy, cx + 1, " ")
      put(cy, cx + 2, "/")
      put(cy, cx + 3, ")")
    else
      put(cy - 1, cx - 3, "(")
      put(cy - 1, cx - 2, " ")
      put(cy - 1, cx - 1, "<")
      put(cy - 1, cx, ".")
      put(cy - 1, cx + 1, " ")
      put(cy - 1, cx + 2, " ")
      put(cy - 1, cx + 3, ")")
      put(cy, cx - 3, "(")
      put(cy, cx - 2, "\\")
      put(cy, cx - 1, " ")
      put(cy, cx, " ")
      put(cy, cx + 1, " ")
      put(cy, cx + 2, " ")
      put(cy, cx + 3, ")")
    end
    put(cy + 1, cx - 2, "/")
    put(cy + 1, cx - 1, "/")
    put(cy + 1, cx + 1, "\\")
    put(cy + 1, cx + 2, "\\")
  elseif pose == "run" then
    -- Running pose (same as normal but legs alternate)
    put(cy - 2, cx - 2, "/")
    put(cy - 2, cx - 1, "\\")
    put(cy - 2, cx + 1, "/")
    put(cy - 2, cx + 2, "\\")
    put(cy - 1, cx - 3, "(")
    put(cy - 1, cx - 2, " ")
    put(cy - 1, cx - 1, "o")
    put(cy - 1, cx, ".")
    put(cy - 1, cx + 1, "o")
    put(cy - 1, cx + 2, " ")
    put(cy - 1, cx + 3, ")")
    put(cy, cx - 3, "(")
    put(cy, cx - 2, " ")
    put(cy, cx - 1, " ")
    put(cy, cx, " ")
    put(cy, cx + 1, " ")
    put(cy, cx + 2, " ")
    put(cy, cx + 3, ")")
    if cat.idle_ticks % 2 == 0 then
      -- Legs open
      put(cy + 1, cx - 2, "/")
      put(cy + 1, cx - 1, " ")
      put(cy + 1, cx + 1, " ")
      put(cy + 1, cx + 2, "\\")
    else
      -- Legs closed
      put(cy + 1, cx - 2, "|")
      put(cy + 1, cx - 1, "|")
      put(cy + 1, cx + 1, "|")
      put(cy + 1, cx + 2, "|")
    end
  elseif pose == "crouch" then
    -- Crouching pose (I style, direction aware)
    local dir = 1
    if ball.x < cat.x then dir = -1 end
    if dir > 0 then
      -- Facing right
      put(cy - 1, cx + 1, "/")
      put(cy - 1, cx + 2, "\\")
      put(cy - 1, cx + 3, ".")
      put(cy - 1, cx + 4, "/")
      put(cy - 1, cx + 5, "\\")
      put(cy, cx - 2, ">")
      put(cy, cx - 1, "=")
      put(cy, cx, "(")
      put(cy, cx + 1, " ")
      put(cy, cx + 2, "o")
      put(cy, cx + 3, ".")
      put(cy, cx + 4, "o")
      put(cy, cx + 5, " ")
      put(cy, cx + 6, ")")
      put(cy + 1, cx + 1, "\"")
      put(cy + 1, cx + 2, "-")
      put(cy + 1, cx + 3, "-")
      put(cy + 1, cx + 4, "\"")
    else
      -- Facing left
      put(cy - 1, cx - 3, "/")
      put(cy - 1, cx - 2, "\\")
      put(cy - 1, cx - 1, ".")
      put(cy - 1, cx, "/")
      put(cy - 1, cx + 1, "\\")
      put(cy, cx - 4, "(")
      put(cy, cx - 3, " ")
      put(cy, cx - 2, "o")
      put(cy, cx - 1, ".")
      put(cy, cx, "o")
      put(cy, cx + 1, " ")
      put(cy, cx + 2, ")")
      put(cy, cx + 3, "=")
      put(cy, cx + 4, "<")
      put(cy + 1, cx - 2, "\"")
      put(cy + 1, cx - 1, "-")
      put(cy + 1, cx, "-")
      put(cy + 1, cx + 1, "\"")
    end
  else
    -- Normal chasing pose
    put(cy - 2, cx - 2, "/")
    put(cy - 2, cx - 1, "\\")
    put(cy - 2, cx + 1, "/")
    put(cy - 2, cx + 2, "\\")
    put(cy - 1, cx - 3, "(")
    put(cy - 1, cx - 2, " ")
    put(cy - 1, cx - 1, "o")
    put(cy - 1, cx, ".")
    put(cy - 1, cx + 1, "o")
    put(cy - 1, cx + 2, " ")
    put(cy - 1, cx + 3, ")")
    put(cy, cx - 3, "(")
    put(cy, cx - 2, " ")
    put(cy, cx - 1, " ")
    put(cy, cx, " ")
    put(cy, cx + 1, " ")
    put(cy, cx + 2, " ")
    put(cy, cx + 3, ")")
    put(cy + 1, cx - 2, "/")
    put(cy + 1, cx - 1, "/")
    put(cy + 1, cx + 1, "\\")
    put(cy + 1, cx + 2, "\\")
  end

  -- Place ball (powerline half-circles)
  local bx, by = ball.x, ball.y
  if by >= 1 and by <= field_height and bx >= 2 and bx <= width then
    if bx - 1 >= 1 then grid[by][bx - 1] = "\xee\x82\xb6" end
    if bx <= width then grid[by][bx] = "\xee\x82\xb4" end
  end

  local lines = {}
  for r = 1, field_height do
    table.insert(lines, table.concat(grid[r]))
  end
  return lines
end

dashboard.section.header.val = build_header()

dashboard.section.buttons.val = {
  dashboard.button("f", "  Find File",       ":Telescope find_files<CR>"),
  dashboard.button("w", "  Find Word",       ":Telescope live_grep<CR>"),
  dashboard.button("r", "  Recent Files",    ":Telescope oldfiles<CR>"),
  dashboard.button("e", "  File Browser",    ":NvimTreeToggle<CR>"),
  dashboard.button("c", "  Colorschemes",    ":Telescope colorscheme<CR>"),
  dashboard.button("n", "  New File",        ":enew<CR>"),
  dashboard.button("q", "  Quit",            ":qa<CR>"),
}



-- Dashboard green theme
vim.cmd("hi AlphaHeader ctermfg=113 guifg=#87d787")
vim.cmd("hi AlphaIcon ctermfg=113 guifg=#87d787")
vim.cmd("hi AlphaText ctermfg=245 guifg=#8a8a8a")
vim.cmd("hi AlphaShortcut ctermfg=75 guifg=#5fafff")
vim.cmd("hi AlphaFooter ctermfg=65 guifg=#5f875f")
dashboard.section.header.opts.hl = "AlphaHeader"
dashboard.section.footer.opts.hl = "AlphaFooter"
for _, btn in ipairs(dashboard.section.buttons.val) do
  btn.opts.hl = "AlphaText"
  btn.opts.hl_shortcut = "AlphaShortcut"
  btn.opts.shortcut = btn.opts.shortcut or ""
  btn.opts.hl = {{"AlphaIcon", 0, 5}, {"AlphaText", 5, -1}}
end

dashboard.section.footer.val = {
  "",
  "[ \\ff Find File | \\fg Grep | \\fb Buffers | F2 Cheatsheet | F3 NvimTree ]",
}

dashboard.config.opts.noautocmd = true
alpha.setup(dashboard.config)

-- Animate cat chasing ball
local timer = nil
local function start_animation()
  if timer then return end
  timer = vim.loop.new_timer()
  timer:start(0, 200, vim.schedule_wrap(function()
    if not timer then return end
    if vim.bo.filetype ~= 'alpha' then
      timer:stop()
      timer:close()
      timer = nil
      return
    end
    -- Sleep after 1 minute idle (200 ticks * 300ms = 60s)
    cat.idle_ticks = cat.idle_ticks + 1
    if cat.idle_ticks > 200 and not cat.sleeping then
      cat.sleeping = true
    end
    if cat.sleeping then
      move_ball()
    else
      move_ball()
      move_cat()
    end
    dashboard.section.header.val = build_header()
    vim.o.lazyredraw = true
    pcall(vim.cmd, 'AlphaRedraw')
    vim.o.lazyredraw = false
  end))
end

-- Wake cat on real key press
vim.on_key(function(key)
  if vim.bo.filetype == 'alpha' and cat.sleeping and key ~= '' then
    cat.sleeping = false
    cat.idle_ticks = 0
  end
end)

start_animation()
vim.api.nvim_create_autocmd('BufEnter', {
  callback = function()
    if vim.bo.filetype == 'alpha' then
      start_animation()
    end
  end,
})
ALPHA

" Auto-refresh statusline for LSP progress updates
lua << REFRESH
local refresh_timer = vim.loop.new_timer()
refresh_timer:start(0, 1000, vim.schedule_wrap(function()
  vim.cmd('redrawstatus')
end))
REFRESH

lua << GITSIGNS
pcall(function()
  require('gitsigns').setup({
    current_line_blame = false,
  })
  -- \gl Git blame (left panel, q to close)
  vim.keymap.set('n', '<leader>gl', function()
    local code_win = vim.api.nvim_get_current_win()
    vim.cmd('highlight CursorLine cterm=underline ctermbg=NONE')
    vim.wo[code_win].cursorline = true
    vim.wo[code_win].cursorbind = true
    vim.cmd('Git blame')
    vim.schedule(function()
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == 'fugitiveblame' then
          vim.wo[win].cursorline = true
          vim.wo[win].cursorbind = true
          -- Strip code, keep sha+author+date and append commit message
          vim.bo[buf].modifiable = true
          local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
          local msg_cache = {}
          for i, line in ipairs(lines) do
            local annotation = line:match('^(.-%))')
            if annotation then
              local sha = line:match('^(%x+)')
              if sha and not msg_cache[sha] then
                local msg = vim.fn.system('git log -1 --format=%s ' .. sha):gsub('\n$', '')
                msg_cache[sha] = msg
              end
              lines[i] = annotation .. ' ' .. (msg_cache[sha] or '')
            end
          end
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
          vim.bo[buf].modifiable = false
          vim.bo[buf].modified = false
          vim.wo[win].wrap = false
        end
      end
    end)
  end, { silent = true, noremap = true })
  -- fugitive blame: Enter opens side-by-side diff in new tab, q closes blame
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'fugitiveblame',
    callback = function()
      vim.keymap.set('n', '<CR>', function()
        local line = vim.fn.getline('.')
        local sha = line:match('^(%x+)')
        if not sha then return end
        vim.cmd('wincmd l')
        local file_dir = vim.fn.expand('%:p:h')
        local file_name = vim.fn.expand('%:t')
        local prefix = vim.fn.system('git -C ' .. vim.fn.shellescape(file_dir) .. ' rev-parse --show-prefix'):gsub('\n$', '')
        local rel_file = prefix .. file_name
        vim.cmd('tabnew')
        vim.cmd('lcd ' .. vim.fn.fnameescape(file_dir))
        vim.cmd('Gedit ' .. sha .. '~1:' .. rel_file)
        vim.cmd('diffthis')
        local nop_keys = {'<leader>ff', '<leader>fg', '<leader>fr', '<leader>fb', 'w', 'q', 'ss'}
        for _, key in ipairs(nop_keys) do
          vim.keymap.set('n', key, '<Nop>', {buffer = true, silent = true})
          vim.keymap.set('v', key, '<Nop>', {buffer = true, silent = true})
        end
        vim.cmd('rightbelow vnew')
        vim.cmd('Gedit ' .. sha .. ':' .. rel_file)
        vim.cmd('diffthis')
        for _, key in ipairs(nop_keys) do
          vim.keymap.set('n', key, '<Nop>', {buffer = true, silent = true})
          vim.keymap.set('v', key, '<Nop>', {buffer = true, silent = true})
        end
      end, { buffer = true, silent = true })
      vim.keymap.set('n', 'q', function()
        vim.cmd('close')
        vim.wo.cursorline = false
        vim.wo.cursorbind = false
        vim.cmd('highlight CursorLine cterm=NONE ctermbg=NONE')
      end, { buffer = true, silent = true })
      vim.keymap.set('n', 'ss', '<Nop>', { buffer = true, silent = true })
      vim.keymap.set('n', 's', '<Nop>', { buffer = true, silent = true })
      vim.api.nvim_create_autocmd('BufWinLeave', {
        buffer = 0,
        once = true,
        callback = function()
          vim.schedule(function()
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              vim.wo[win].cursorline = false
              vim.wo[win].cursorbind = false
            end
            vim.cmd('highlight CursorLine cterm=NONE ctermbg=NONE')
          end)
        end,
      })
      vim.wo.number = true
      vim.wo.relativenumber = false
    end,
  })
  -- \gd side-by-side diff in new tab
  vim.keymap.set('n', '<leader>gd', function()
    vim.cmd('tab split')
    vim.cmd('Gitsigns diffthis')
    vim.schedule(function()
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        vim.wo[win].winfixbuf = false
      end
    end)
  end, { silent = true, noremap = true })
  -- \q close tab
  vim.keymap.set('n', '<leader>q', function()
    if #vim.api.nvim_list_tabpages() > 1 then
      vim.cmd('tabc')
    end
  end, { silent = true, noremap = true })
end)
GITSIGNS

" cursorline (only enabled during blame)
set nocursorline
