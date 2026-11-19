test_a_rendered_project_passes_its_own_gates() {
  project="$SCRATCH/acme-tool"
  render_into "$SCRATCH/render"
  bootstrap_like_tui_repo "$project"
  cp -R "$SCRATCH/render/." "$project/"
  git -C "$project" add -A
  git -C "$project" commit -q -m "Set up acme-tool"

  set +e
  (cd "$project" && CI=1 scripts/gates.sh) >"$SCRATCH/gates.log" 2>&1
  status=$?
  set -e
  [ "$status" = 0 ] || cat "$SCRATCH/gates.log"
  assert_eq "$(cd "$project" && scripts/version-check.sh origin/main HEAD 2>&1)" "the pull request leaves the version to the release workflow"
  assert_status "$status" 0
  echo "note: rendered gates ran $(awk '/^test result: ok\./ { sum += $4 } END { print sum }' "$SCRATCH/gates.log") tests"
  assert_eq "$(git -C "$project" status --porcelain)" ""
}

test_a_name_that_matches_a_cli_test_still_compiles_the_tests() {
  assert_status "$(cargo_check_tests help-exits-zero)" 0
}

test_rerun_after_the_gates_fail_on_a_tree_formatted_by_cargo_ends_like_an_uninterrupted_run() {
  real_cargo_fmt
  stop_once fail '^cargo clippy '
  assert_file "$SCRATCH/stop/fired"
  assert_status "$RERUN_STATUS" 0
  assert_eq "$STATE_DIFF" ""
}

test_rerun_after_an_interrupt_right_after_cargo_fmt_ends_like_an_uninterrupted_run() {
  real_cargo_fmt
  stop_once interrupt '^cargo fmt$'
  assert_file "$SCRATCH/stop/fired"
  assert_status "$RERUN_STATUS" 0
  assert_eq "$STATE_DIFF" ""
}

bootstrap_like_tui_repo() {
  git init -q --bare "$SCRATCH/origin.git"
  git init -q "$1"
  git -C "$1" remote add origin "$SCRATCH/origin.git"
  printf '# acme-tool\n' >"$1/README.md"
  cp "$SCRATCH/render/LICENSE" "$SCRATCH/render/CHANGELOG.md" "$1/"
  mkdir -p "$1/.github/workflows"
  printf 'name: CI\non: [pull_request]\njobs:\n  check:\n    runs-on: ubuntu-latest\n    steps:\n      - run: echo check\n' >"$1/.github/workflows/ci.yml"
  git -C "$1" add -A
  git -C "$1" commit -q -m Bootstrap
  git -C "$1" push -q origin main
  git -C "$1" fetch -q origin
  git -C "$1" switch -q --no-track -c phase-0-foundations origin/main
}

render_into() {
  export CARGO_HOME="${CARGO_HOME:-$REAL_HOME/.cargo}"
  export RUSTUP_HOME="${RUSTUP_HOME:-$REAL_HOME/.rustup}"
  TUI_REPO_OWNER=acme \
    TUI_REPO_TAP=acme/homebrew-tap \
    TUI_REPO_AUTHOR="Jane Q. O'Neil & Co" \
    "$TUI_REPO" "${2:-acme-tool}" \
    --description "Docks & ships / tides | crews, (fast)! 100% sure? it's 'fine' #1 C++ {ok}" \
    --render-only "$1" </dev/null >/dev/null
}

cargo_check_tests() {
  local out="$SCRATCH/check-$1" status
  render_into "$out" "$1"
  set +e
  (cd "$out" && cargo check --tests --locked) >"$out.log" 2>&1
  status=$?
  set -e
  [ "$status" = 0 ] || cat "$out.log" >&2
  echo "$status"
}

real_cargo_fmt() {
  CARGO_HOME="${CARGO_HOME:-$REAL_HOME/.cargo}"
  RUSTUP_HOME="${RUSTUP_HOME:-$REAL_HOME/.rustup}"
  FAKE_REAL_CARGO="$(resolve_tool cargo)"
  FAKE_REAL_PATH="$ORIGINAL_PATH"
  export CARGO_HOME RUSTUP_HOME FAKE_REAL_CARGO FAKE_REAL_PATH
}
