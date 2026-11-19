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
    "$TUI_REPO" acme-tool \
    --description "Docks & ships / tides | crews, (fast)! 100% sure? it's 'fine' #1 C++ {ok}" \
    --render-only "$1" </dev/null >/dev/null
}
