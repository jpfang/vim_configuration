## Vim / Nvim / Tmux Configuration

### Quick Install

```bash
git clone <this-repo> ~/Git/vim_configuration
cd ~/Git/vim_configuration
./install.sh
source ~/.bashrc
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
| `install.sh` | Auto-install nvim, clangd, shellcheck, vim-plug, coc extensions, symlinks |

### LSP Support

| Language | LSP Server | coc Extension |
|----------|-----------|---------------|
| C/C++ | clangd 18.1.3 | coc-clangd |
| Python | pyright | coc-pyright |
| Bash/Shell | bash-language-server + shellcheck | coc-sh |

### Keybindings

See [cheatsheet.txt](cheatsheet.txt) for the full list of keybindings (also accessible via `F2` in nvim).

### Notes

- Terminal alias: `vi` launches nvim with `TERM=putty-256color` (fixes Home/End on KiTTY)
- For C++ projects: run `genClangd <build_path>` in project root to generate `compile_commands.json`
