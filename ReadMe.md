## Vim / Nvim / Tmux Configuration

### Quick Install

```bash
git clone <this-repo> ~/Git/vim_configuration
cd ~/Git/vim_configuration
./install.sh
source ~/.bashrc
vi +PlugInstall +qa
vi +'CocInstall coc-clangd coc-pyright'
```

### Requirements

- Ubuntu (tested on 20.04+)
- git, wget, curl, unzip
- node.js (for coc.nvim)
- KiTTY/PuTTY terminal with Nerd Font (e.g. SauceCodePro Nerd Font Mono)

### What's included

| File | Purpose |
|------|---------|
| `.vimrc` | Vim/Nvim shared config (Vundle plugins, colorscheme fisa) |
| `.tmux.conf` | Tmux config with powerline status bar |
| `.config/nvim/init.vim` | Nvim-specific config (coc.nvim, IDE keybindings) |
| `.config/nvim/coc-settings.json` | clangd/pyright LSP settings |
| `install.sh` | Auto-install nvim, clangd, vim-plug, symlinks |

### Nvim Keybindings

| Key | Action |
|-----|--------|
| `w` | Go to definition |
| `q` | Jump back |
| `sw` | Find references |
| `gy` | Type definition |
| `gi` | Implementation |
| `K` | Hover docs |
| `\rn` | Rename symbol |
| `[d` / `]d` | Prev/next diagnostic |
| `\f` | Format |
| `Tab` | Next completion |
| `Enter` | Confirm completion |

### Notes

- Terminal alias: `vi` launches nvim with `TERM=putty-256color` (fixes Home/End on KiTTY)
- For C++ projects: run `genClangd <build_path>` in project root to generate `compile_commands.json`
