#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OS="$(uname -s)"

echo "=== Installing vim/nvim/tmux configuration (${OS}) ==="

# --- Symlink dotfiles ---
ln -sf "$SCRIPT_DIR/.vimrc" ~/.vimrc
ln -sf "$SCRIPT_DIR/.tmux.conf" ~/.tmux.conf
cp -r "$SCRIPT_DIR/.vim" ~/

# --- genClangd script ---
mkdir -p ~/usr/bin
ln -sf "$SCRIPT_DIR/usr/bin/genClangd" ~/usr/bin/genClangd

# --- Nvim config ---
mkdir -p ~/.config/nvim
ln -sf "$SCRIPT_DIR/.config/nvim/init.vim" ~/.config/nvim/init.vim
ln -sf "$SCRIPT_DIR/cheatsheet.txt" ~/.config/nvim/cheatsheet.txt
sed "s|\$HOME|$HOME|g" "$SCRIPT_DIR/.config/nvim/coc-settings.json.template" > ~/.config/nvim/coc-settings.json

# --- Install nvim ---
if [ ! -f ~/.local/bin/nvim ]; then
    echo "Installing nvim 0.10.4..."
    mkdir -p ~/.local/bin
    if [ "$OS" = "Darwin" ]; then
        curl -fLo /tmp/nvim-macos.tar.gz https://github.com/neovim/neovim/releases/download/v0.10.4/nvim-macos-arm64.tar.gz
        tar -xzf /tmp/nvim-macos.tar.gz -C ~/.local
        ln -sf ~/.local/nvim-macos-arm64/bin/nvim ~/.local/bin/nvim
        rm -f /tmp/nvim-macos.tar.gz
    else
        wget -qO ~/.local/bin/nvim https://github.com/neovim/neovim/releases/download/v0.10.4/nvim-linux-x86_64.appimage
        chmod +x ~/.local/bin/nvim
    fi
fi

# --- Install vim-plug for nvim ---
if [ ! -f ~/.local/share/nvim/site/autoload/plug.vim ]; then
    echo "Installing vim-plug..."
    curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# --- Install clangd ---
if [ ! -f ~/.local/lib/clangd_18.1.3/bin/clangd ]; then
    echo "Installing clangd 18.1.3..."
    mkdir -p /tmp/clangd_install
    if [ "$OS" = "Darwin" ]; then
        curl -fLo /tmp/clangd_install/clangd.zip https://github.com/clangd/clangd/releases/download/18.1.3/clangd-mac-18.1.3.zip
    else
        wget -qO /tmp/clangd_install/clangd.zip https://github.com/clangd/clangd/releases/download/18.1.3/clangd-linux-18.1.3.zip
    fi
    unzip -qo /tmp/clangd_install/clangd.zip -d /tmp/clangd_install
    mkdir -p ~/.local/lib
    mv /tmp/clangd_install/clangd_18.1.3 ~/.local/lib/
    rm -rf /tmp/clangd_install
fi

# --- Check ripgrep (needed by Telescope live_grep) ---
if ! command -v rg &>/dev/null; then
    echo "WARNING: ripgrep not found. Telescope live_grep requires rg."
    if [ "$OS" = "Darwin" ]; then
        echo "  Install with: brew install ripgrep"
    else
        echo "  Install with: sudo apt install ripgrep"
    fi
fi

# --- Install node (needed by coc.nvim) ---
if ! command -v node &>/dev/null; then
    echo "WARNING: node.js not found. coc.nvim requires node >= 16."
    if [ "$OS" = "Darwin" ]; then
        echo "  Install with: brew install node"
    else
        echo "  Install with: sudo apt install nodejs"
    fi
fi

# --- Setup shell config ---
if [ "$OS" = "Darwin" ]; then
    SHELL_RC=~/.zshrc
    ALIAS_CMD="alias vi=nvim"
else
    SHELL_RC=~/.bashrc
    ALIAS_CMD="alias vi='TERM=putty-256color nvim'"
fi

BASHRC_MARKER="# vim_configuration setup"
if ! grep -q "$BASHRC_MARKER" "$SHELL_RC"; then
    echo "" >> "$SHELL_RC"
    echo "$BASHRC_MARKER" >> "$SHELL_RC"
    echo 'export PATH="$HOME/.local/bin:$HOME/usr/bin:$PATH"' >> "$SHELL_RC"
    echo "$ALIAS_CMD" >> "$SHELL_RC"
fi

echo ""
echo "=== Syncing nvim plugins... ==="
~/.local/bin/nvim --headless -c 'PlugInstall --sync' -c 'qa' 2>/dev/null
~/.local/bin/nvim --headless -c 'CocInstall -sync coc-clangd coc-pyright' -c 'qa' 2>/dev/null

echo ""
echo "=== Done! Run: source $SHELL_RC ==="
