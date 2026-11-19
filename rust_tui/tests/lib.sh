REAL_HOME="${REAL_HOME:-$HOME}"
ORIGINAL_PATH="${ORIGINAL_PATH:-$PATH}"
export REAL_HOME ORIGINAL_PATH
RECIPE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TUI_REPO="$RECIPE/tui_repo"
FAKES="$RECIPE/tests/fakes"
HARNESS_TOOLS="bash sh env git perl python3 jq awk sed grep tr cat mkdir rm rmdir ls cp mv ln chmod date dirname basename head tail wc sort uniq cut mktemp find xargs touch readlink diff tee id uname stat paste expr comm od cmp true false printf test"

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

resolve_tool() {
  if [ "$1" = python3 ]; then
    HOME="$REAL_HOME" PATH="$ORIGINAL_PATH" python3 -c 'import sys; print(sys.executable)' 2>/dev/null || true
  else
    PATH="$ORIGINAL_PATH" type -P "$1" 2>/dev/null || true
  fi
}

harness_check() {
  local tool real
  for tool in $HARNESS_TOOLS; do
    real="$(resolve_tool "$tool")"
    case "$real" in
      /*) ;;
      *) echo "the test harness cannot find $tool on PATH" ;;
    esac
  done
}
