# PATH Configuration
# Note: Homebrew PATH is set in .zprofile
# Note: DOTFILES_DIR/bin PATH is set in .zshenv
# Note: Rust/Cargo PATH is set in .zshenv via cargo env

# Global npm packages
export PATH="/usr/local/share/npm/bin:$PATH"

# Serverless
export PATH="$HOME/.serverless/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# LM Studio CLI
export PATH="$PATH:$HOME/.lmstudio/bin"
