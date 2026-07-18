#!/usr/bin/env bats

setup() {
  export TEST_ROOT
  TEST_ROOT="$(mktemp -d)"
  export AGENT_SECRETS_DIR="$TEST_ROOT/secrets"
  export AGENT_SECRETS_TEMPLATE="$AGENT_SECRETS_DIR/env.1password"
  export AGENT_SECRETS_CACHE="$AGENT_SECRETS_DIR/env.cache"
  export AGENT_SECRETS_OP_ACCOUNT="test.1password.local"
  AGENT_SECRETS="$BATS_TEST_DIRNAME/../bin/agent-secrets"

  mkdir -p "$AGENT_SECRETS_DIR" "$TEST_ROOT/bin"
}

teardown() {
  rm -rf -- "$TEST_ROOT"
}

install_op_stub() {
  cat > "$TEST_ROOT/bin/op" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

output=''
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --out-file)
      output="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [[ "${OP_STUB_FAIL:-0}" == "1" ]]; then
  exit 1
fi

printf '%s\n' \
  '# resolved cache' \
  'WORK_BRAIN_BEARER_TOKEN=resolved token=with spaces' \
  'CODEX_CA_CERTIFICATE=/etc/ssl/cert.pem' > "$output"
EOF
  chmod 755 "$TEST_ROOT/bin/op"
}

make_valid_cache() {
  printf '%s\n' \
    '# local cache' \
    'FIRST_SECRET=value with spaces' \
    'SECOND_SECRET=value=with=equals' > "$AGENT_SECRETS_CACHE"
  chmod 700 "$AGENT_SECRETS_DIR"
  chmod 600 "$AGENT_SECRETS_CACHE"
}

@test "refresh writes a validated cache with private permissions" {
  install_op_stub
  printf '%s\n' 'FIRST_SECRET={{ op://Test/item/value }}' > "$AGENT_SECRETS_TEMPLATE"

  run env PATH="$TEST_ROOT/bin:$PATH" "$AGENT_SECRETS" refresh

  [ "$status" -eq 0 ]
  [ "$(stat -f '%Lp' "$AGENT_SECRETS_DIR" 2>/dev/null || stat -c '%a' "$AGENT_SECRETS_DIR")" = "700" ]
  [ "$(stat -f '%Lp' "$AGENT_SECRETS_CACHE" 2>/dev/null || stat -c '%a' "$AGENT_SECRETS_CACHE")" = "600" ]
  grep -q '^WORK_BRAIN_BEARER_TOKEN=resolved token=with spaces$' "$AGENT_SECRETS_CACHE"
  run find "$AGENT_SECRETS_DIR" -name 'env.cache.tmp.*' -print
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "a worktree command stores its cache under the active dotfiles directory" {
  install_op_stub
  local active_dotfiles="$TEST_ROOT/active-dotfiles"
  unset AGENT_SECRETS_DIR AGENT_SECRETS_TEMPLATE AGENT_SECRETS_CACHE
  mkdir -p "$active_dotfiles/agent-config/secrets"

  run env \
    DOTFILES_DIR="$active_dotfiles" \
    PATH="$TEST_ROOT/bin:$PATH" \
    "$AGENT_SECRETS" refresh

  [ "$status" -eq 0 ]
  [ -f "$active_dotfiles/agent-config/secrets/env.cache" ]
  [ ! -f "$BATS_TEST_DIRNAME/../agent-config/secrets/env.cache" ]
}

@test "a failed refresh preserves the previous cache" {
  install_op_stub
  make_valid_cache
  cp "$AGENT_SECRETS_CACHE" "$TEST_ROOT/original-cache"
  printf '%s\n' 'FIRST_SECRET={{ op://Test/item/value }}' > "$AGENT_SECRETS_TEMPLATE"

  run env PATH="$TEST_ROOT/bin:$PATH" OP_STUB_FAIL=1 "$AGENT_SECRETS" refresh

  [ "$status" -ne 0 ]
  cmp "$TEST_ROOT/original-cache" "$AGENT_SECRETS_CACHE"
  run find "$AGENT_SECRETS_DIR" -name 'env.cache.tmp.*' -print
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exec exports cache values and forwards arguments and exit status" {
  make_valid_cache

  # shellcheck disable=SC2016
  run "$AGENT_SECRETS" exec sh -c \
    'printf "%s|%s|%s" "$FIRST_SECRET" "$SECOND_SECRET" "$1"; exit 7' \
    test-command 'argument with spaces'

  [ "$status" -eq 7 ]
  [ "$output" = 'value with spaces|value=with=equals|argument with spaces' ]
}

@test "exec treats shell syntax in values as data" {
  local marker="$TEST_ROOT/should-not-exist"
  # shellcheck disable=SC2016
  printf '%s\n' 'SAFE=value' "EVIL=\$(touch $marker)" > "$AGENT_SECRETS_CACHE"
  chmod 700 "$AGENT_SECRETS_DIR"
  chmod 600 "$AGENT_SECRETS_CACHE"

  run "$AGENT_SECRETS" exec true

  [ "$status" -eq 0 ]
  [ ! -e "$marker" ]
}

@test "exec fails closed for a missing cache" {
  run "$AGENT_SECRETS" exec true

  [ "$status" -ne 0 ]
  [[ "$output" == *"agent-secrets refresh"* ]]
}

@test "exec rejects unresolved references and permissive files" {
  printf '%s\n' 'FIRST_SECRET={{ op://Test/item/value }}' > "$AGENT_SECRETS_CACHE"
  chmod 700 "$AGENT_SECRETS_DIR"
  chmod 600 "$AGENT_SECRETS_CACHE"

  run "$AGENT_SECRETS" exec true
  [ "$status" -ne 0 ]
  [[ "$output" == *'unresolved 1Password reference'* ]]

  printf '%s\n' 'FIRST_SECRET=value' > "$AGENT_SECRETS_CACHE"
  chmod 644 "$AGENT_SECRETS_CACHE"

  run "$AGENT_SECRETS" exec true
  [ "$status" -ne 0 ]
  [[ "$output" == *'expected 600'* ]]

  chmod 600 "$AGENT_SECRETS_CACHE"
  chmod 755 "$AGENT_SECRETS_DIR"

  run "$AGENT_SECRETS" exec true
  [ "$status" -ne 0 ]
  [[ "$output" == *'expected 700'* ]]
}

@test "status omits values and clear removes only the cache" {
  make_valid_cache
  printf '%s\n' 'template remains' > "$AGENT_SECRETS_TEMPLATE"

  run "$AGENT_SECRETS" status
  [ "$status" -eq 0 ]
  [[ "$output" == *'Status: valid'* ]]
  [[ "$output" != *'value with spaces'* ]]

  run "$AGENT_SECRETS" clear
  [ "$status" -eq 0 ]
  [ ! -e "$AGENT_SECRETS_CACHE" ]
  [ -e "$AGENT_SECRETS_TEMPLATE" ]
}
