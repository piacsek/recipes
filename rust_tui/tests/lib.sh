REAL_HOME="${REAL_HOME:-$HOME}"
ORIGINAL_PATH="${ORIGINAL_PATH:-$PATH}"
RECIPE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TUI_REPO="$RECIPE/tui_repo"
FAKES="$RECIPE/tests/fakes"

scratch_setup() {
  SCRATCH="$(mktemp -d /tmp/rust_tui_test.XXXXXX)"
  export HOME="$SCRATCH/home"
  mkdir -p "$HOME"
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM XDG_CONFIG_HOME
  export GIT_CONFIG_NOSYSTEM=1
  git config --global user.name "Acme Author"
  git config --global user.email "author@example.com"
  git config --global init.defaultBranch main
  for var in $(env | awk -F= '/^TUI_REPO_|_DENYLIST=/ { print $1 }'); do
    unset "$var"
  done
}

scratch_teardown() {
  chmod -R u+w "$SCRATCH" 2>/dev/null || true
  rm -rf "$SCRATCH"
}

fail() {
  printf 'assertion failed: %s\n' "$1" >&2
  exit 1
}

assert_eq() {
  [ "$1" = "$2" ] || fail "expected [$2], got [$1]"
}

assert_contains() {
  case "$1" in
    *"$2"*) ;;
    *) fail "expected to contain [$2], got [$1]" ;;
  esac
}

refute_contains() {
  case "$1" in
    *"$2"*) fail "expected not to contain [$2], got [$1]" ;;
    *) ;;
  esac
}

assert_file() {
  [ -f "$1" ] || fail "no file $1"
}

refute_exists() {
  { [ ! -e "$1" ] && [ ! -L "$1" ]; } || fail "$1 exists"
}

assert_executable() {
  [ -x "$1" ] || fail "$1 is not executable"
}

assert_status() {
  [ "$1" = "$2" ] || fail "expected exit status $2, got $1"
}
