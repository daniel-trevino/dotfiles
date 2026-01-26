# ASDF Version Manager

if [ -f "$HOME/.asdf/asdf.sh" ]; then
  . $HOME/.asdf/asdf.sh
  export PATH="$HOME/.asdf/shims:$PATH"

  # Append asdf completions to fpath (zsh-native, avoids bash completion issues)
  fpath=(${ASDF_DIR}/completions $fpath)

  # Function to automatically install tools based on .tool-versions
  asdf_auto_install() {
    if [ -f ".tool-versions" ]; then
      asdf install
    fi
  }

  # Hook the function to the shell prompt command
  autoload -U add-zsh-hook
  add-zsh-hook chpwd asdf_auto_install
  asdf_auto_install
fi
