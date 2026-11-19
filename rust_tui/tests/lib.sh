REAL_HOME="${REAL_HOME:-$HOME}"
ORIGINAL_PATH="${ORIGINAL_PATH:-$PATH}"
export REAL_HOME ORIGINAL_PATH
RECIPE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TUI_REPO="$RECIPE/tui_repo"
FAKES="$RECIPE/tests/fakes"
SECRET_TERM="zzqx-unlisted-term"
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

sandbox() {
  local tool real
  mkdir -p "$SCRATCH/bin" "$SCRATCH/shared" "$SCRATCH/projects" "$SCRATCH/remotes" "$SCRATCH/tmp"
  for tool in $HARNESS_TOOLS; do
    real="$(resolve_tool "$tool")"
    case "$real" in
      /*) ln -s "$real" "$SCRATCH/bin/$tool" ;;
      *) fail "the test harness cannot find $tool on PATH" ;;
    esac
  done
  for tool in gh cargo tmux freeze chrome sleep; do
    ln -s "$FAKES/$tool" "$SCRATCH/bin/$tool"
  done
  printf '%s\n' "$SECRET_TERM" >"$SCRATCH/shared/denylist"
  git config --global url."$SCRATCH/remotes/".insteadOf "git@github.com:"
  PROJECT="$SCRATCH/projects/acme-tool"
  FAKE_STATE="$SCRATCH/state"
  FAKE_LOG="$SCRATCH/fake.log"
  REMOTE="$SCRATCH/remotes/acme/acme-tool.git"
  FAKE_NOW="$(date -u +%Y-%m-%d)T10:05:00Z"
  export FAKE_STATE FAKE_LOG FAKE_NOW
}

flow() {
  flow_asking --yes </dev/null
}

flow_asking() {
  PATH="$SCRATCH/bin" \
    PROJECTS_DIR="$SCRATCH/projects" \
    FAKE_REMOTES="$SCRATCH/remotes" \
    CHROME="${CHROME:-$SCRATCH/bin/chrome}" \
    TUI_REPO_SHARED_DENYLIST="${SHARED_DENYLIST:-$SCRATCH/shared/denylist}" \
    TUI_REPO_DESCRIPTION="${TUI_REPO_DESCRIPTION:-Keeps the acme fleet in line}" \
    TUI_REPO_TAP="${TAP:-acme/homebrew-tap}" \
    TMPDIR="$SCRATCH/tmp" \
    "$TUI_REPO" acme-tool "$@"
}

remote_git() {
  git --git-dir "$REMOTE" "$@"
}

stop_once() {
  sandbox
  flow >/dev/null 2>&1 || true
  REFERENCE="$(final_state)"
  reset_sandbox
  stoppable
  set +e
  FAKE_STOP_HOW="$1" FAKE_STOP_AT="$2" FAKE_STOP_NTH="${3:-1}" flow >"$SCRATCH/stopped.log" 2>&1
  RERUN_OUTPUT="$(flow 2>&1)"
  RERUN_STATUS=$?
  set -e
  [ "$RERUN_STATUS" = 0 ] || printf 'the rerun said:\n%s\n' "$RERUN_OUTPUT" >&2
  STATE_DIFF="$(diff <(printf '%s\n' "$REFERENCE") <(final_state) || true)"
}

stoppable() {
  local tool
  mkdir -p "$SCRATCH/real" "$SCRATCH/stop"
  for tool in git mv ln gh cargo chrome; do
    mv "$SCRATCH/bin/$tool" "$SCRATCH/real/$tool"
    ln -s "$FAKES/stoppable" "$SCRATCH/bin/$tool"
  done
  FAKE_REAL_BIN="$SCRATCH/real"
  FAKE_STOP_DIR="$SCRATCH/stop"
  FAKE_STOP_TARGET="$TUI_REPO"
  FAKE_PS="$(resolve_tool ps)"
  export FAKE_REAL_BIN FAKE_STOP_DIR FAKE_STOP_TARGET FAKE_PS
}

reset_sandbox() {
  rm -rf "$SCRATCH/projects" "$SCRATCH/remotes" "$SCRATCH/state" "$SCRATCH/tmp" "$SCRATCH/fake.log" "$HOME/.config" "$HOME/.local"
  mkdir -p "$SCRATCH/projects" "$SCRATCH/remotes" "$SCRATCH/tmp"
}

final_state() {
  local ref path json
  for ref in $(remote_git for-each-ref --format='%(refname:short)' refs/heads); do
    printf 'remote %s: %s\n' "$ref" "$(remote_git log --format=%s "$ref" | tr '\n' '|')"
    remote_git ls-tree -r --name-only "$ref" >"$SCRATCH/paths"
    while IFS= read -r path; do
      printf '  %s %s\n' "$path" "$(remote_git show "$ref:$path" | masked | git hash-object --stdin)"
    done <"$SCRATCH/paths"
  done
  for json in "$FAKE_STATE"/*.json; do
    printf '%s %s\n' "${json##*/}" "$(jq -cS . "$json" | masked)"
  done
  printf 'denylist link: %s\n' "$(readlink "$HOME/.config/acme-tool-dev/denylist")"
  printf 'dev link: %s\n' "$(readlink "$HOME/.local/bin/acme-tool-dev")"
  printf 'local branches: %s\n' "$(git -C "$PROJECT" for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads | tr '\n' '|')"
  printf 'local main is remote main: %s\n' "$([ "$(git -C "$PROJECT" rev-parse main)" = "$(remote_git rev-parse main)" ] && echo yes || echo no)"
  printf 'worktree head is remote branch: %s\n' "$([ "$(git -C "$PROJECT/.claude/worktrees/phase-0-foundations" rev-parse -q --verify HEAD 2>/dev/null)" = "$(remote_git rev-parse -q --verify phase-0-foundations)" ] && echo yes || echo no)"
  printf 'worktree status: %s\n' "$(git -C "$PROJECT/.claude/worktrees/phase-0-foundations" status --porcelain --untracked-files=all | tr '\n' '|')"
}

masked() {
  LC_ALL=C sed -E 's/[0-9a-f]{7,64}/SHA/g; s/[0-9]{4}-[0-9]{2}-[0-9]{2}/DATE/g; s/[0-9]{2}:[0-9]{2}:[0-9]{2}/TIME/g'
}
