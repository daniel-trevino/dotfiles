export NVM_DIR="$HOME/.nvm"

# Lazy-load NVM: only initialize when nvm/node/npm/npx is first called (~500ms savings)
# Named without a leading underscore so shell snapshots (e.g. Claude Code) keep it.
# Always removes the wrappers first; otherwise an inherited NVM_BIN would make
# node() call itself forever.
lazy_load_nvm() {
  unset -f nvm node npm npx 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
nvm() { lazy_load_nvm; nvm "$@"; }
node() { lazy_load_nvm; node "$@"; }
npm() { lazy_load_nvm; npm "$@"; }
npx() { lazy_load_nvm; npx "$@"; }
