#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Installing vim/nvim/tmux configuration ==="

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
sed "s|\$HOME|$HOME|g" "$SCRIPT_DIR/.config/nvim/coc-settings.json.template" > ~/.config/nvim/coc-settings.json

# --- Install nvim (AppImage) ---
if [ ! -f ~/.local/bin/nvim ]; then
    echo "Installing nvim 0.10.4..."
    mkdir -p ~/.local/bin
    wget -qO ~/.local/bin/nvim https://github.com/neovim/neovim/releases/download/v0.10.4/nvim-linux-x86_64.appimage
    chmod +x ~/.local/bin/nvim
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
    wget -qO /tmp/clangd_install/clangd.zip https://github.com/clangd/clangd/releases/download/18.1.3/clangd-linux-18.1.3.zip
    unzip -qo /tmp/clangd_install/clangd.zip -d /tmp/clangd_install
    mkdir -p ~/.local/lib
    mv /tmp/clangd_install/clangd_18.1.3 ~/.local/lib/
    rm -rf /tmp/clangd_install
fi

# --- Install node (needed by coc.nvim) ---
if ! command -v node &>/dev/null; then
    echo "WARNING: node.js not found. coc.nvim requires node. Please install it."
fi

# --- Setup bashrc entries ---
BASHRC_MARKER="# vim_configuration setup"
if ! grep -q "$BASHRC_MARKER" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "$BASHRC_MARKER" >> ~/.bashrc
    echo 'export PATH="$HOME/.local/bin:$HOME/usr/bin:$PATH"' >> ~/.bashrc
    echo "alias vi='TERM=putty-256color nvim'" >> ~/.bashrc
fi

echo ""
echo "=== Done! ==="
echo ""
echo "Next steps:"
echo "  1. source ~/.bashrc"
echo "  2. vi +PlugInstall +qa"
echo "  3. vi +'CocInstall coc-clangd coc-pyright'"
echo ""
echo "For C++ projects, generate compile_commands.json:"
echo "  cd ~/Git/work && genClangd <build_path>"
