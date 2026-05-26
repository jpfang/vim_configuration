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
nnoremap < :tabp<CR>
nnoremap > :tabn<CR>
nmap q <C-o>
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
vnoremap <leader>fg "zy:Telescope live_grep default_text=<C-r>z<CR>
nnoremap <leader>fb :Telescope buffers<CR>

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
  -- Clear jump list after opening file so q won't jump back to nvim-tree
  vim.keymap.set('n', '<CR>', function()
    api.node.open.edit()
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
