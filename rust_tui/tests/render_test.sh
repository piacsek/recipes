DESCRIPTION="Docks & ships / tides | crews, (fast)! 100% sure? it's 'fine' #1 C++ {ok}"

test_render_writes_the_crate_name_into_cargo_toml() {
  render acme-tool
  assert_contains "$(cat "$OUT/Cargo.toml")" $'\nname = "acme-tool"\n'
}

test_render_writes_the_description_exactly_into_cargo_toml() {
  render acme-tool
  assert_contains "$(cat "$OUT/Cargo.toml")" "description = \"$DESCRIPTION\""
}

test_render_writes_the_description_exactly_into_the_flake() {
  render acme-tool
  assert_contains "$(cat "$OUT/flake.nix")" "description = \"$DESCRIPTION\";"
}

test_render_writes_the_description_exactly_into_the_usage() {
  render acme-tool
  assert_contains "$(cat "$OUT/src/main.rs")" "\"acme-tool: $DESCRIPTION\\n\\nusage: acme-tool [--help | --version | changelog]\""
}

test_render_writes_the_description_exactly_into_the_formula() {
  render acme-tool
  assert_contains "$(cat "$OUT/scripts/homebrew-formula.sh")" "  desc \"$DESCRIPTION\""
}

test_render_writes_the_description_line_into_the_readme() {
  render acme-tool
  assert_contains "$(cat "$OUT/README.md")" $'# acme-tool\n\n'"$DESCRIPTION."$'\n\n## Installation'
}

test_render_leaves_no_placeholder() {
  render acme-tool
  assert_eq "$(grep -rlE '\{\{(name|snake|upper|class|owner|tap_repo|tap|description|author|year|ruleset_id|date|main_sha|start|pr_ref|draft_pr)\}\}' "$OUT" || true)" ""
}

test_render_leaves_no_harbour_in_contents() {
  render acme-tool
  assert_eq "$(grep -rli harbour "$OUT" || true)" ""
}

test_render_leaves_no_harbour_in_file_names() {
  render acme-tool
  assert_eq "$(find "$OUT" -iname '*harbour*')" ""
}

test_render_for_another_owner_leaves_no_piacsek() {
  render acme-tool
  assert_eq "$(grep -rli piacsek "$OUT" || true)" ""
}

test_render_names_the_owner_repository() {
  render acme-tool
  assert_contains "$(cat "$OUT/Cargo.toml")" 'repository = "https://github.com/acme/acme-tool"'
}

test_render_installs_from_the_tap() {
  render acme-tool
  assert_contains "$(cat "$OUT/README.md")" $'\nbrew install acme/tap/acme-tool\n'
}

test_render_points_the_tap_job_at_the_tap_repository() {
  render acme-tool
  assert_contains "$(cat "$OUT/.github/workflows/release.yml")" "repository: acme/homebrew-tap"
}

test_render_runs_the_tap_job_only_in_the_project_repository() {
  render acme-tool
  assert_contains "$(cat "$OUT/.github/workflows/release.yml")" "github.repository == 'acme/acme-tool'"
}

test_render_names_the_formula_class_in_camel_case() {
  render acme-tool
  assert_contains "$(cat "$OUT/scripts/homebrew-formula.sh")" "class AcmeTool < Formula"
}

test_render_names_the_denylist_variable_in_upper_snake_case() {
  render acme-tool
  assert_contains "$(cat "$OUT/scripts/scrub-check.sh")" 'list="${ACME_TOOL_DENYLIST:-$HOME/.config/acme-tool-dev/denylist}"'
}

test_render_names_rust_helpers_in_snake_case() {
  render acme-tool
  assert_contains "$(cat "$OUT/tests/cli.rs")" "fn acme_tool(args: &[&str]) -> Output {"
}

test_render_runs_the_binary_by_its_name() {
  render acme-tool
  assert_contains "$(cat "$OUT/tests/cli.rs")" 'env!("CARGO_BIN_EXE_acme-tool")'
}

test_render_writes_the_author_and_year_into_the_license() {
  render acme-tool
  assert_contains "$(cat "$OUT/LICENSE")" "Copyright (c) $(date +%Y) Jane Q. O'Neil & Co"
}

test_render_writes_the_ruleset_id() {
  render acme-tool
  assert_contains "$(cat "$OUT/.github/AGENTS.md")" "gh api repos/acme/acme-tool/rulesets/777 --jq"
}

test_render_keeps_scripts_executable() {
  render acme-tool
  assert_executable "$OUT/scripts/ship.sh"
}

test_render_keeps_the_lock_sorted_by_package_name() {
  render acme-tool
  assert_eq "$(lock_order "$OUT/Cargo.lock")" "sorted"
}

test_render_writes_the_lock_entry_of_the_package() {
  render acme-tool
  assert_contains "$(cat "$OUT/Cargo.lock")" $'[[package]]\nname = "acme-tool"\nversion = "0.0.0"\n'
}

test_render_of_a_name_late_in_the_alphabet_keeps_the_lock_sorted() {
  render zz-top
  assert_eq "$(lock_order "$OUT/Cargo.lock")" "sorted"
}

test_render_lists_phase_0_in_the_plan_index() {
  render acme-tool
  assert_contains "$(cat "$OUT/PLAN.md")" "(plans/phase-0-foundations.md)"
}

test_render_writes_a_metrics_row_for_phase_0() {
  render acme-tool
  assert_contains "$(cat "$OUT/plans/metrics.md")" $'\n| 0 | '
}

test_render_says_no_agent_took_part_in_phase_0() {
  render acme-tool
  assert_contains "$(grep '^| 0 |' "$OUT/plans/metrics.md")" "| no agent | no agent | no agent | no agent |"
}

test_render_records_no_hurdle_for_phase_0() {
  render acme-tool
  assert_contains "$(cat "$OUT/plans/phase-0-foundations.md")" $'## Hurdles\n\n- none recorded'
}

test_render_says_the_project_was_scaffolded_from_the_recipe() {
  render acme-tool
  assert_contains "$(cat "$OUT/AGENTS.md")" "the \`rust_tui\` recipe"
}

test_render_formats_the_rendered_project() {
  render acme-tool
  assert_eq "$(cat "$SCRATCH/fake.log")" "$OUT cargo fmt"
}

test_render_refuses_a_target_that_is_not_empty() {
  mkdir -p "$SCRATCH/out"
  touch "$SCRATCH/out/keep"
  OUT="$SCRATCH/out"
  set +e
  output="$(render_env acme-tool "$DESCRIPTION" "$TUI_REPO" --render-only "$OUT" 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  assert_contains "$output" "is not empty"
}

test_render_writes_an_executable_screenshot_script() {
  render acme-tool
  assert_executable "$OUT/scripts/screenshots.sh"
}

test_render_screenshots_the_help_of_the_release_binary() {
  render acme-tool
  assert_contains "$(cat "$OUT/scripts/screenshots.sh")" 'bin="$root/target/release/acme-tool"'
}

test_render_shoots_docs_help_png_from_the_help_flag() {
  render acme-tool
  assert_contains "$(cat "$OUT/scripts/screenshots.sh")" $'\nshoot help '
}

test_render_writes_the_ansi_converter() {
  render acme-tool
  assert_file "$OUT/scripts/truecolor.py"
}

test_render_produces_no_screenshot() {
  render acme-tool
  refute_exists "$OUT/docs/help.png"
}

test_render_writes_the_screenshots_agreement() {
  render acme-tool
  assert_contains "$(cat "$OUT/AGENTS.md")" "- **Screenshots in PRs.** "
}

test_render_lists_the_screenshot_script_in_the_layout() {
  render acme-tool
  assert_contains "$(cat "$OUT/AGENTS.md")" $'\nscripts/screenshots.sh '
}

test_render_no_longer_lists_the_screenshot_scripts_as_waiting() {
  render acme-tool
  refute_contains "$(cat "$OUT/PLAN.md")" "scripts/screenshots.sh"
}

test_render_still_lists_the_demo_driver_as_waiting() {
  render acme-tool
  assert_contains "$(cat "$OUT/PLAN.md")" "drive-demo.sh"
}

test_render_mentions_the_help_screenshot_in_the_phase_0_plan() {
  render acme-tool
  assert_contains "$(cat "$OUT/plans/phase-0-foundations.md")" "docs/help.png"
}

test_render_writes_a_changelog_of_its_header_alone() {
  render acme-tool
  assert_eq "$(cat "$OUT/CHANGELOG.md")" "# Changelog"
}

test_render_makes_the_first_release_v0_0_1() {
  render acme-tool
  git -C "$OUT" init -q
  git -C "$OUT" add -A
  git -C "$OUT" commit -q -m "Set up acme-tool"
  assert_eq "$("$OUT/scripts/next-version.sh")" "0.0.1"
}

render() {
  OUT="$SCRATCH/out"
  render_env "$1" "$DESCRIPTION" "$TUI_REPO" --render-only "$OUT" >/dev/null
}

render_env() {
  local name="$1" description="$2"
  shift 2
  TUI_REPO_NAME="$name" \
    TUI_REPO_DESCRIPTION="$description" \
    TUI_REPO_OWNER=acme \
    TUI_REPO_TAP=acme/homebrew-tap \
    TUI_REPO_AUTHOR="Jane Q. O'Neil & Co" \
    TUI_REPO_RULESET_ID=777 \
    FAKE_LOG="$SCRATCH/fake.log" \
    PATH="$FAKES:$PATH" \
    "$@" </dev/null
}

lock_order() {
  awk '/^name = / { print $3 }' "$1" | LC_ALL=C sort -c 2>/dev/null && echo sorted || echo unsorted
}
