SECRET_TERM="zzqx-unlisted-term"

test_flow_creates_the_repository_before_its_settings() {
  sandbox
  flow >/dev/null
  assert_before "gh repo create acme/acme-tool" "gh api --silent -X PATCH repos/acme/acme-tool"
}

test_flow_sets_the_settings_before_the_token_permissions() {
  sandbox
  flow >/dev/null
  assert_before "gh api --silent -X PATCH repos/acme/acme-tool" "gh api --silent -X PUT repos/acme/acme-tool/actions/permissions/workflow"
}

test_flow_sets_the_token_permissions_before_the_ruleset() {
  sandbox
  flow >/dev/null
  assert_before "gh api --silent -X PUT repos/acme/acme-tool/actions/permissions/workflow" "-X POST repos/acme/acme-tool/rulesets"
}

test_flow_creates_the_ruleset_before_the_labels() {
  sandbox
  flow >/dev/null
  assert_before "-X POST repos/acme/acme-tool/rulesets" "gh label create"
}

test_flow_creates_the_labels_before_the_pull_request() {
  sandbox
  flow >/dev/null
  assert_before "gh label create" "gh pr create"
}

test_flow_writes_the_pull_request_body_after_opening_it() {
  sandbox
  flow >/dev/null
  assert_before "gh pr create" "gh pr edit"
}

test_flow_exits_zero() {
  sandbox
  set +e
  flow >/dev/null 2>&1
  status=$?
  set -e
  assert_status "$status" 0
}

test_flow_pushes_a_bootstrap_main_with_a_changelog_of_its_heading_alone() {
  sandbox
  flow >/dev/null
  assert_eq "$(remote_git show main:CHANGELOG.md)" "# Changelog"
}

test_flow_pushes_a_bootstrap_main_with_the_license() {
  sandbox
  flow >/dev/null
  assert_contains "$(remote_git show main:LICENSE)" "Copyright (c) $(date +%Y) Acme Author"
}

test_flow_pushes_a_bootstrap_main_with_a_check_job() {
  sandbox
  flow >/dev/null
  assert_contains "$(remote_git show main:.github/workflows/ci.yml)" $'\n  check:\n'
}

test_flow_keeps_main_at_the_bootstrap_commit() {
  sandbox
  flow >/dev/null
  assert_eq "$(remote_git rev-list --count main)" "1"
}

test_flow_squashes_only() {
  sandbox
  flow >/dev/null
  assert_eq "$(jq -r .allow_merge_commit "$FAKE_STATE/repo.json")" "false"
}

test_flow_deletes_merged_branches() {
  sandbox
  flow >/dev/null
  assert_eq "$(jq -r .delete_branch_on_merge "$FAKE_STATE/repo.json")" "true"
}

test_flow_turns_on_push_protection() {
  sandbox
  flow >/dev/null
  assert_eq "$(jq -r .security_and_analysis.secret_scanning_push_protection.status "$FAKE_STATE/repo.json")" "enabled"
}

test_flow_gives_the_actions_token_read_access() {
  sandbox
  flow >/dev/null
  assert_eq "$(jq -r .default_workflow_permissions "$FAKE_STATE/workflow.json")" "read"
}

test_flow_creates_one_main_ruleset() {
  sandbox
  flow >/dev/null
  assert_eq "$(jq '[.[] | select(.name == "main")] | length' "$FAKE_STATE/rulesets.json")" "1"
}

test_flow_requires_check_first() {
  sandbox
  flow >/dev/null
  assert_eq "$(required_check 0)" "check"
}

test_flow_requires_audit_second() {
  sandbox
  flow >/dev/null
  assert_eq "$(required_check 1)" "audit"
}

test_flow_does_not_require_version_before_the_merge() {
  sandbox
  flow >/dev/null
  assert_eq "$(required_check_count)" "2"
}

test_flow_creates_the_adversarial_review_label_in_grey() {
  sandbox
  flow >/dev/null
  assert_eq "$(label_field adversarial-review-finding color)" "ededed"
}

test_flow_creates_the_adversarial_review_label_without_description() {
  sandbox
  flow >/dev/null
  assert_eq "$(label_field adversarial-review-finding description)" ""
}

test_flow_creates_the_development_cycle_label_in_green() {
  sandbox
  flow >/dev/null
  assert_eq "$(label_field development-cycle-improvement color)" "0E8A16"
}

test_flow_describes_the_development_cycle_label() {
  sandbox
  flow >/dev/null
  assert_eq "$(label_field development-cycle-improvement description)" "Makes iterating on this project faster or more reliable"
}

test_flow_creates_the_maintenance_label_in_blue() {
  sandbox
  flow >/dev/null
  assert_eq "$(label_field "Type: Maintenance" color)" "BFD4F2"
}

test_flow_describes_the_maintenance_label() {
  sandbox
  flow >/dev/null
  assert_eq "$(label_field "Type: Maintenance" description)" "Upkeep with no new feature: tooling, refactors, internal quality"
}

test_flow_shows_the_missing_labels_in_the_summary() {
  sandbox
  assert_contains "$(flow)" "create adversarial-review-finding, development-cycle-improvement, Type: Maintenance"
}

test_rerun_leaves_a_label_changed_by_hand() {
  sandbox
  flow >/dev/null
  jq 'map(if .name == "Type: Maintenance" then .color = "000000" else . end)' "$FAKE_STATE/labels.json" >"$SCRATCH/labels.json"
  mv "$SCRATCH/labels.json" "$FAKE_STATE/labels.json"
  flow >/dev/null
  assert_eq "$(label_field "Type: Maintenance" color)" "000000"
}

test_flow_adds_the_worktree_under_claude_worktrees() {
  sandbox
  flow >/dev/null
  assert_eq "$(git -C "$PROJECT/.claude/worktrees/phase-0-foundations" rev-parse --abbrev-ref HEAD)" "phase-0-foundations"
}

test_flow_opens_a_draft_pull_request() {
  sandbox
  flow >/dev/null
  assert_eq "$(jq -r '.[0].isDraft' "$FAKE_STATE/prs.json")" "true"
}

test_flow_titles_the_pull_request_in_plain_language() {
  sandbox
  flow >/dev/null
  assert_eq "$(jq -r '.[0].title' "$FAKE_STATE/prs.json")" "Set up acme-tool with its checks, guidelines and automatic releases"
}

test_flow_assigns_the_pull_request_to_the_owner() {
  sandbox
  flow >/dev/null
  assert_contains "$(cat "$FAKE_LOG")" "gh pr create --draft --assignee @me"
}

test_flow_commits_the_help_screenshot_with_the_phase_0_commit() {
  sandbox
  flow >/dev/null
  assert_eq "$(remote_git cat-file -t "$(phase_0_commit):docs/help.png")" "blob"
}

test_flow_takes_the_screenshot_after_rendering() {
  sandbox
  flow >/dev/null
  assert_before "$PROJECT/.claude/worktrees/phase-0-foundations cargo build --release" "chrome --headless"
}

test_flow_takes_the_screenshot_before_opening_the_pull_request() {
  sandbox
  flow >/dev/null
  assert_before "chrome --headless" "gh pr create"
}

test_flow_pins_the_screenshot_to_its_commit() {
  sandbox
  flow >/dev/null
  assert_contains "$(pr_body)" "(https://raw.githubusercontent.com/acme/acme-tool/$(phase_0_commit)/docs/help.png)"
}

test_flow_records_the_pull_request_in_the_metrics() {
  sandbox
  flow >/dev/null
  assert_contains "$(remote_git show phase-0-foundations:plans/metrics.md)" $'\n| 0 | #1 | '
}

test_flow_records_the_draft_time_in_the_metrics() {
  sandbox
  flow >/dev/null
  assert_contains "$(remote_git show phase-0-foundations:plans/metrics.md)" " | 10:05:00Z | no review |"
}

test_flow_ships_the_metrics_as_a_second_commit() {
  sandbox
  flow >/dev/null
  assert_eq "$(remote_git log -1 --format=%s phase-0-foundations)" "Record the phase 0 pull request in the metrics"
}

test_pull_request_body_carries_one_mermaid_block() {
  sandbox
  flow >/dev/null
  assert_eq "$(pr_body | grep -c '^```mermaid$')" "1"
}

test_pull_request_diagram_shows_the_first_release_job() {
  sandbox
  flow >/dev/null
  assert_contains "$(pr_body)" "[\"$(release_job 1)\"]"
}

test_pull_request_diagram_shows_the_second_release_job() {
  sandbox
  flow >/dev/null
  assert_contains "$(pr_body)" "[\"$(release_job 2)\"]"
}

test_pull_request_diagram_shows_the_third_release_job() {
  sandbox
  flow >/dev/null
  assert_contains "$(pr_body)" "[\"$(release_job 3)\"]"
}

test_pull_request_diagram_shows_the_fourth_release_job() {
  sandbox
  flow >/dev/null
  assert_contains "$(pr_body)" "[\"$(release_job 4)\"]"
}

test_pull_request_diagram_shows_the_fifth_release_job() {
  sandbox
  flow >/dev/null
  assert_contains "$(pr_body)" "[\"$(release_job 5)\"]"
}

test_pull_request_diagram_shows_the_sixth_release_job() {
  sandbox
  flow >/dev/null
  assert_contains "$(pr_body)" "[\"$(release_job 6)\"]"
}

test_release_workflow_has_the_six_jobs_the_diagram_shows() {
  assert_eq "$(release_job_count)" "6"
}

test_pull_request_diagram_names_the_tap() {
  sandbox
  flow >/dev/null
  assert_contains "$(pr_body)" "acme/homebrew-tap"
}

test_pull_request_diagram_leaves_out_the_description() {
  sandbox
  flow >/dev/null
  refute_contains "$(pr_body)" "Keeps the acme fleet in line"
}

test_pull_request_summary_is_two_lines() {
  sandbox
  flow >/dev/null
  assert_eq "$(pr_summary | grep -c .)" "2"
}

test_pull_request_summary_has_at_most_three_sentences() {
  sandbox
  flow >/dev/null
  assert_eq "$(pr_summary | grep -oE '[.!?]( |$)' | wc -l | awk '$1 <= 3 { print "ok" }')" "ok"
}

test_pull_request_body_points_at_the_tap_token_in_one_line() {
  sandbox
  flow >/dev/null
  assert_eq "$(pr_body | grep -c TAP_TOKEN)" "1"
}

test_pull_request_body_names_the_owner_steps() {
  sandbox
  flow >/dev/null
  assert_contains "$(pr_body)" "rerun \`tui_repo acme-tool\`"
}

test_flow_links_the_denylist_to_the_shared_list() {
  sandbox
  flow >/dev/null
  assert_eq "$(readlink "$HOME/.config/acme-tool-dev/denylist")" "$SCRATCH/shared/denylist"
}

test_flow_leaves_an_existing_denylist() {
  sandbox
  mkdir -p "$HOME/.config/acme-tool-dev"
  printf 'own-term\n' >"$HOME/.config/acme-tool-dev/denylist"
  flow >/dev/null
  assert_eq "$(cat "$HOME/.config/acme-tool-dev/denylist")" "own-term"
}

test_flow_never_prints_the_denylist() {
  sandbox
  refute_contains "$(flow 2>&1)" "$SECRET_TERM"
}

test_flow_refuses_without_the_shared_denylist() {
  sandbox
  rm "$SCRATCH/shared/denylist"
  set +e
  output="$(flow 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  assert_contains "$output" "$SCRATCH/shared/denylist"
  refute_exists "$FAKE_STATE/repo.json"
}

test_flow_ends_with_the_tap_token_block() {
  sandbox
  assert_eq "$(flow | tail -n 6)" "$(tap_block)"
}

test_flow_prints_the_rerun_line_above_the_tap_token_block() {
  sandbox
  assert_eq "$(flow | tail -n 7 | head -n 1)" "After merging the pull request, rerun tui_repo acme-tool to require the version check on main."
}

test_flow_says_tap_token_is_set_when_it_is() {
  sandbox
  flow >/dev/null
  printf '[{"name":"TAP_TOKEN"}]\n' >"$FAKE_STATE/secrets.json"
  assert_eq "$(flow | tail -n 1)" "TAP_TOKEN: already set"
}

test_flow_leaves_out_the_tap_token_block_when_it_is_set() {
  sandbox
  flow >/dev/null
  printf '[{"name":"TAP_TOKEN"}]\n' >"$FAKE_STATE/secrets.json"
  refute_contains "$(flow)" "pbpaste"
}

test_validation_failure_creates_nothing() {
  sandbox
  set +e
  TUI_REPO_DESCRIPTION='Costs $5' flow >/dev/null 2>&1
  status=$?
  set -e
  assert_status "$status" 1
  refute_exists "$PROJECT"
  refute_exists "$FAKE_STATE/repo.json"
  refute_exists "$HOME/.config/acme-tool-dev"
}

test_decline_creates_nothing() {
  sandbox
  set +e
  printf 'n\n' | flow_asking >/dev/null 2>&1
  status=$?
  set -e
  assert_status "$status" 1
  refute_exists "$PROJECT"
  refute_exists "$FAKE_STATE/repo.json"
  refute_exists "$HOME/.config/acme-tool-dev"
}

test_foreign_directory_is_refused() {
  sandbox
  mkdir -p "$PROJECT"
  touch "$PROJECT/notes.txt"
  set +e
  output="$(flow 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  assert_contains "$output" "is not a clone of acme/acme-tool"
  refute_exists "$FAKE_STATE/repo.json"
}

test_missing_tmux_is_refused_before_anything_is_created() {
  sandbox
  rm "$SCRATCH/bin/tmux"
  set +e
  output="$(flow 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  assert_contains "$output" "tmux is missing: brew install tmux"
  refute_exists "$FAKE_STATE/repo.json"
}

test_missing_freeze_is_refused_before_anything_is_created() {
  sandbox
  rm "$SCRATCH/bin/freeze"
  set +e
  output="$(flow 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  assert_contains "$output" "freeze is missing: brew install charmbracelet/tap/freeze"
  refute_exists "$FAKE_STATE/repo.json"
}

test_missing_chrome_is_refused_before_anything_is_created() {
  sandbox
  set +e
  output="$(CHROME="$SCRATCH/no-chrome" flow 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  assert_contains "$output" "Google Chrome or chromium is missing"
  refute_exists "$FAKE_STATE/repo.json"
}

test_a_full_rerun_makes_no_mutating_call() {
  sandbox
  flow >/dev/null
  : >"$FAKE_LOG"
  flow >/dev/null
  assert_eq "$(mutating_calls)" ""
}

test_a_full_rerun_pushes_nothing() {
  sandbox
  flow >/dev/null
  before="$(remote_git for-each-ref)"
  flow >/dev/null
  assert_eq "$(remote_git for-each-ref)" "$before"
}

test_a_full_rerun_skips_every_step() {
  sandbox
  flow >/dev/null
  assert_eq "$(flow | grep -c ': already done, skipped$')" "14"
}

test_a_full_rerun_exits_zero_without_asking() {
  sandbox
  flow >/dev/null
  set +e
  flow_asking </dev/null >/dev/null 2>&1
  status=$?
  set -e
  assert_status "$status" 0
}

test_rerun_after_a_failed_repository_creation_completes() {
  sandbox
  fail_then_rerun "repo create"
  assert_contains "$(pr_body)" '```mermaid'
}

test_rerun_after_failed_settings_completes() {
  sandbox
  fail_then_rerun "-X PATCH"
  assert_eq "$(jq -r .allow_merge_commit "$FAKE_STATE/repo.json")" "false"
}

test_rerun_after_failed_token_permissions_completes() {
  sandbox
  fail_then_rerun "-X PUT repos/acme/acme-tool/actions"
  assert_eq "$(jq -r .default_workflow_permissions "$FAKE_STATE/workflow.json")" "read"
}

test_rerun_after_a_failed_ruleset_creation_creates_one_ruleset() {
  sandbox
  fail_then_rerun "-X POST repos/acme/acme-tool/rulesets"
  assert_eq "$(jq length "$FAKE_STATE/rulesets.json")" "1"
}

test_rerun_after_a_failed_label_completes() {
  sandbox
  fail_then_rerun "label create Type"
  assert_eq "$(label_field "Type: Maintenance" color)" "BFD4F2"
}

test_rerun_after_a_failed_pull_request_creation_opens_one() {
  sandbox
  fail_then_rerun "pr create"
  assert_eq "$(jq length "$FAKE_STATE/prs.json")" "1"
}

test_rerun_after_a_failed_body_writes_it() {
  sandbox
  fail_then_rerun "pr edit"
  assert_contains "$(pr_body)" '```mermaid'
}

test_rerun_after_a_failed_body_records_the_metrics() {
  sandbox
  fail_then_rerun "pr edit"
  assert_contains "$(remote_git show phase-0-foundations:plans/metrics.md)" $'\n| 0 | #1 | '
}

test_a_failed_screenshot_leaves_the_branch_half_way() {
  sandbox
  set +e
  FAKE_CHROME_FAIL=1 flow >/dev/null 2>&1
  set -e
  assert_eq "$(git -C "$PROJECT" rev-list --count origin/main..phase-0-foundations)" "0"
}

test_rerun_after_a_failed_screenshot_ships_the_branch() {
  sandbox
  set +e
  FAKE_CHROME_FAIL=1 flow >/dev/null 2>&1
  set -e
  flow >/dev/null
  assert_eq "$(remote_git cat-file -t "$(phase_0_commit):docs/help.png")" "blob"
}

test_a_rejected_push_leaves_one_commit_on_the_local_branch() {
  sandbox
  reject_branch_pushes
  set +e
  flow >/dev/null 2>&1
  set -e
  assert_eq "$(git -C "$PROJECT" rev-list --count origin/main..phase-0-foundations)" "1"
}

test_rerun_after_a_rejected_push_ships_the_local_commit() {
  sandbox
  reject_branch_pushes
  set +e
  flow >/dev/null 2>&1
  set -e
  local_commit="$(git -C "$PROJECT" rev-parse phase-0-foundations)"
  allow_branch_pushes
  flow >/dev/null
  assert_eq "$(phase_0_commit)" "$local_commit"
}

test_rerun_after_a_rejected_push_opens_the_pull_request() {
  sandbox
  reject_branch_pushes
  set +e
  flow >/dev/null 2>&1
  set -e
  allow_branch_pushes
  flow >/dev/null
  assert_eq "$(jq length "$FAKE_STATE/prs.json")" "1"
}

test_a_local_branch_with_other_work_is_left_alone() {
  sandbox
  reject_branch_pushes
  set +e
  flow >/dev/null 2>&1
  set -e
  git -C "$PROJECT/.claude/worktrees/phase-0-foundations" commit -q --allow-empty -m "Other work"
  allow_branch_pushes
  flow >/dev/null
  assert_eq "$(jq length "$FAKE_STATE/prs.json" 2>/dev/null || echo none)" "none"
}

test_rerun_after_the_merge_requires_version() {
  sandbox
  flow >/dev/null
  merge_phase_0
  flow >/dev/null
  assert_eq "$(required_check 2)" "version"
}

test_rerun_after_the_merge_says_what_it_added() {
  sandbox
  flow >/dev/null
  merge_phase_0
  assert_contains "$(flow)" "added version to the required checks"
}

test_rerun_after_the_merge_drops_the_rerun_line() {
  sandbox
  flow >/dev/null
  merge_phase_0
  refute_contains "$(flow)" "rerun tui_repo acme-tool"
}

test_rerun_after_the_merge_keeps_checks_added_by_hand() {
  sandbox
  flow >/dev/null
  add_required_check_by_hand lint
  merge_phase_0
  flow >/dev/null
  assert_eq "$(required_check 2)" "lint"
}

test_rerun_after_the_merge_adds_version_after_checks_added_by_hand() {
  sandbox
  flow >/dev/null
  add_required_check_by_hand lint
  merge_phase_0
  flow >/dev/null
  assert_eq "$(required_check 3)" "version"
}

test_rerun_after_the_merge_keeps_check_first() {
  sandbox
  flow >/dev/null
  add_required_check_by_hand lint
  merge_phase_0
  flow >/dev/null
  assert_eq "$(required_check 0)" "check"
}

test_rerun_after_the_merge_adds_audit_when_it_was_removed_by_hand() {
  sandbox
  flow >/dev/null
  remove_required_check_by_hand audit
  merge_phase_0
  flow >/dev/null
  assert_eq "$(required_check_count)" "3"
}

test_rerun_after_the_merge_changes_nothing_twice() {
  sandbox
  flow >/dev/null
  merge_phase_0
  flow >/dev/null
  : >"$FAKE_LOG"
  flow >/dev/null
  assert_eq "$(mutating_calls)" ""
}

test_a_failed_repository_probe_creates_nothing() {
  sandbox
  probe_fails_on_a_fresh_run "repos/acme/acme-tool --jq .full_name"
  assert_status "$status" 1
  assert_contains "$output" "could not find out whether acme/acme-tool exists"
  refute_exists "$PROJECT"
  refute_exists "$HOME/.config/acme-tool-dev"
  assert_eq "$(mutating_calls)" ""
}

test_a_failed_repository_probe_on_a_rerun_changes_nothing() {
  sandbox
  probe_fails_on_a_rerun "repos/acme/acme-tool --jq .full_name"
  assert_status "$status" 1
  assert_contains "$output" "could not find out whether acme/acme-tool exists"
  assert_eq "$(mutating_calls)" ""
}

test_a_failed_main_probe_on_a_rerun_pushes_nothing() {
  sandbox
  probe_fails_on_a_rerun "branches/main"
  assert_status "$status" 1
  assert_contains "$output" "could not find out whether main is on acme/acme-tool"
  refute_contains "$output" "==> push main"
}

test_a_failed_main_probe_in_an_https_clone_pushes_nothing() {
  sandbox
  flow >/dev/null
  git -C "$PROJECT" remote set-url origin https://github.com/acme/acme-tool.git
  : >"$FAKE_LOG"
  set +e
  output="$(FAKE_GH_FAIL="branches/main" flow 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  refute_contains "$output" "push main to acme/acme-tool"
}

test_a_rerun_in_an_https_clone_skips_the_push() {
  sandbox
  flow >/dev/null
  git -C "$PROJECT" remote set-url origin https://github.com/acme/acme-tool.git
  assert_contains "$(flow)" "==> push main: already done, skipped"
}

test_a_failed_branch_probe_clones_nothing() {
  sandbox
  set +e
  FAKE_GH_FAIL="pr create" flow >/dev/null 2>&1
  set -e
  rm -rf "$PROJECT"
  : >"$FAKE_LOG"
  set +e
  output="$(FAKE_GH_FAIL="branches/phase-0-foundations" flow 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  assert_contains "$output" "could not find out whether phase-0-foundations is on acme/acme-tool"
  refute_exists "$PROJECT"
  assert_eq "$(mutating_calls)" ""
}

test_a_failed_scaffold_probe_on_a_rerun_changes_nothing() {
  sandbox
  probe_fails_on_a_rerun "contents/scripts/ship.sh"
  assert_status "$status" 1
  assert_contains "$output" "could not find out whether main holds scripts/ship.sh"
  assert_eq "$(mutating_calls)" ""
}

test_a_failed_pull_request_probe_on_a_rerun_changes_nothing() {
  sandbox
  probe_fails_on_a_rerun "pr list"
  assert_status "$status" 1
  assert_contains "$output" "could not find out which pull request phase-0-foundations has"
  assert_eq "$(mutating_calls)" ""
}

test_a_failed_settings_probe_on_a_rerun_changes_nothing() {
  sandbox
  probe_fails_on_a_rerun "allow_squash_merge"
  assert_status "$status" 1
  assert_contains "$output" "could not find out the repository settings"
  assert_eq "$(mutating_calls)" ""
}

test_a_failed_permissions_probe_on_a_rerun_changes_nothing() {
  sandbox
  probe_fails_on_a_rerun "permissions/workflow --jq"
  assert_status "$status" 1
  assert_contains "$output" "could not find out the Actions token permissions"
  assert_eq "$(mutating_calls)" ""
}

test_a_failed_ruleset_list_probe_on_a_rerun_creates_no_ruleset() {
  sandbox
  probe_fails_on_a_rerun "rulesets --jq"
  assert_status "$status" 1
  assert_contains "$output" "could not find out the rulesets of acme/acme-tool"
  assert_eq "$(mutating_calls)" ""
}

test_a_failed_ruleset_probe_after_the_merge_changes_nothing() {
  sandbox
  flow >/dev/null
  merge_phase_0
  : >"$FAKE_LOG"
  set +e
  output="$(FAKE_GH_FAIL="rulesets/777 --jq" flow 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  assert_contains "$output" "could not find out the required checks of the main ruleset"
  assert_eq "$(mutating_calls)" ""
}

test_a_failed_label_probe_on_a_rerun_creates_no_label() {
  sandbox
  probe_fails_on_a_rerun "label list"
  assert_status "$status" 1
  assert_contains "$output" "could not find out the labels of acme/acme-tool"
  assert_eq "$(mutating_calls)" ""
}

test_a_failed_secret_probe_prints_no_tap_token_steps() {
  sandbox
  probe_fails_on_a_rerun "secret list"
  assert_status "$status" 1
  assert_contains "$output" "could not find out whether TAP_TOKEN is set"
  refute_contains "$output" "pbpaste"
}

test_rerun_after_a_render_cut_at_one_third_ships_every_file() {
  sandbox
  interrupt_render_after 1 3
  flow >/dev/null
  assert_eq "$(shipped_file_count)" "$(($(template_file_count) + 1))"
}

test_rerun_after_a_render_cut_at_two_thirds_ships_every_file() {
  sandbox
  interrupt_render_after 2 3
  flow >/dev/null
  assert_eq "$(shipped_file_count)" "$(($(template_file_count) + 1))"
}

test_rerun_after_a_render_cut_at_two_thirds_renders_again() {
  sandbox
  interrupt_render_after 2 3
  assert_contains "$(flow)" "==> phase 0 render: render the rust_tui template into the worktree"
}

test_rerun_after_a_finished_render_skips_the_render() {
  sandbox
  interrupt_render_after 3 3
  assert_contains "$(flow)" "==> phase 0 render: already done, skipped"
}

test_a_foreign_untracked_file_in_the_worktree_stops_the_render() {
  sandbox
  interrupt_render_after 1 3
  printf 'mine\n' >"$PROJECT/.claude/worktrees/phase-0-foundations/notes.txt"
  set +e
  output="$(flow 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  assert_contains "$output" "the phase 0 worktree holds changes the render would not write: notes.txt"
  refute_exists "$PROJECT/.claude/worktrees/phase-0-foundations/scripts/ship.sh"
}

test_a_foreign_edit_to_a_tracked_file_stops_the_render() {
  sandbox
  interrupt_render_after 1 3
  printf 'mine\n' >>"$PROJECT/.claude/worktrees/phase-0-foundations/README.md"
  set +e
  output="$(flow 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  assert_contains "$output" "the phase 0 worktree holds changes the render would not write: README.md"
  refute_exists "$PROJECT/.claude/worktrees/phase-0-foundations/scripts/ship.sh"
}

test_a_foreign_edit_to_a_rendered_file_stops_the_render() {
  sandbox
  interrupt_render_after 1 3
  printf 'mine\n' >>"$PROJECT/.claude/worktrees/phase-0-foundations/Cargo.toml"
  set +e
  output="$(flow 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  assert_contains "$output" "Cargo.toml"
  refute_contains "$output" "==> phase 0 pull request"
}

test_a_bootstrap_cut_after_an_empty_directory_is_finished() {
  sandbox
  half_bootstrap 0
  set +e
  flow >/dev/null 2>&1
  status=$?
  set -e
  assert_status "$status" 0
  assert_eq "$(remote_git log -1 --format=%s main)" "Bootstrap"
}

test_a_bootstrap_cut_after_the_workflows_directory_is_finished() {
  sandbox
  half_bootstrap 1
  set +e
  flow >/dev/null 2>&1
  status=$?
  set -e
  assert_status "$status" 0
  assert_eq "$(remote_git log -1 --format=%s main)" "Bootstrap"
}

test_a_bootstrap_cut_after_git_init_is_finished() {
  sandbox
  half_bootstrap 2
  set +e
  flow >/dev/null 2>&1
  status=$?
  set -e
  assert_status "$status" 0
  assert_eq "$(remote_git log -1 --format=%s main)" "Bootstrap"
}

test_a_bootstrap_cut_after_the_origin_is_finished() {
  sandbox
  half_bootstrap 3
  set +e
  flow >/dev/null 2>&1
  status=$?
  set -e
  assert_status "$status" 0
  assert_eq "$(remote_git log -1 --format=%s main)" "Bootstrap"
}

test_a_bootstrap_cut_after_the_readme_is_finished() {
  sandbox
  half_bootstrap 4
  set +e
  flow >/dev/null 2>&1
  status=$?
  set -e
  assert_status "$status" 0
  assert_eq "$(remote_git log -1 --format=%s main)" "Bootstrap"
}

test_a_bootstrap_cut_after_the_license_is_finished() {
  sandbox
  half_bootstrap 5
  set +e
  flow >/dev/null 2>&1
  status=$?
  set -e
  assert_status "$status" 0
  assert_eq "$(remote_git log -1 --format=%s main)" "Bootstrap"
}

test_a_bootstrap_cut_after_the_changelog_is_finished() {
  sandbox
  half_bootstrap 6
  set +e
  flow >/dev/null 2>&1
  status=$?
  set -e
  assert_status "$status" 0
  assert_eq "$(remote_git log -1 --format=%s main)" "Bootstrap"
}

test_a_bootstrap_cut_after_the_ci_workflow_is_finished() {
  sandbox
  half_bootstrap 7
  set +e
  flow >/dev/null 2>&1
  status=$?
  set -e
  assert_status "$status" 0
  assert_eq "$(remote_git log -1 --format=%s main)" "Bootstrap"
}

test_a_bootstrap_cut_after_staging_is_finished() {
  sandbox
  half_bootstrap 8
  set +e
  flow >/dev/null 2>&1
  status=$?
  set -e
  assert_status "$status" 0
  assert_eq "$(remote_git log -1 --format=%s main)" "Bootstrap"
}

test_a_half_bootstrap_with_an_https_origin_is_finished() {
  sandbox
  half_bootstrap 3
  git -C "$PROJECT" remote set-url origin https://github.com/acme/acme-tool.git
  git config --global --add url."$SCRATCH/remotes/".insteadOf "https://github.com/"
  set +e
  flow >/dev/null 2>&1
  status=$?
  set -e
  assert_status "$status" 0
}

test_a_half_bootstrap_with_an_edited_readme_is_refused() {
  sandbox
  half_bootstrap 6
  printf 'mine\n' >>"$PROJECT/README.md"
  set +e
  output="$(flow 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  assert_contains "$output" "is not a clone of acme/acme-tool"
  refute_exists "$FAKE_STATE/repo.json"
}

test_a_half_bootstrap_with_a_foreign_file_and_the_right_origin_is_refused() {
  sandbox
  half_bootstrap 3
  printf 'mine\n' >"$PROJECT/notes.txt"
  set +e
  output="$(flow 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  assert_contains "$output" "is not a clone of acme/acme-tool"
  refute_exists "$FAKE_STATE/repo.json"
}

test_a_half_bootstrap_with_another_origin_is_refused() {
  sandbox
  half_bootstrap 2
  git -C "$PROJECT" remote add origin git@github.com:acme/other.git
  set +e
  output="$(flow 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  assert_contains "$output" "is not a clone of acme/acme-tool"
}

test_a_directory_with_a_commit_but_no_origin_is_refused() {
  sandbox
  half_bootstrap 8
  git -C "$PROJECT" remote remove origin
  git -C "$PROJECT" commit -q -m mine
  set +e
  output="$(flow 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  assert_contains "$output" "is not a clone of acme/acme-tool"
}

sandbox() {
  local tool real
  mkdir -p "$SCRATCH/bin" "$SCRATCH/shared" "$SCRATCH/projects" "$SCRATCH/remotes"
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
    TUI_REPO_SHARED_DENYLIST="$SCRATCH/shared/denylist" \
    TUI_REPO_DESCRIPTION="${TUI_REPO_DESCRIPTION:-Keeps the acme fleet in line}" \
    TUI_REPO_TAP=acme/homebrew-tap \
    "$TUI_REPO" acme-tool "$@"
}

probe_fails_on_a_fresh_run() {
  set +e
  output="$(FAKE_GH_FAIL="$1" flow 2>&1)"
  status=$?
  set -e
}

probe_fails_on_a_rerun() {
  flow >/dev/null
  : >"$FAKE_LOG"
  set +e
  output="$(FAKE_GH_FAIL="$1" flow 2>&1)"
  status=$?
  set -e
}

fail_then_rerun() {
  set +e
  FAKE_GH_FAIL="$1" flow >/dev/null 2>&1
  first=$?
  set -e
  [ "$first" != 0 ] || fail "the run with $1 failing exited 0"
  flow >/dev/null
}

assert_before() {
  local first second
  first="$(grep -nF -- "$1" "$FAKE_LOG" | head -n 1 | cut -d: -f1)"
  second="$(grep -nF -- "$2" "$FAKE_LOG" | head -n 1 | cut -d: -f1)"
  [ -n "$first" ] || fail "no call matching [$1]"
  [ -n "$second" ] || fail "no call matching [$2]"
  [ "$first" -lt "$second" ] || fail "[$1] (line $first) is not before [$2] (line $second)"
}

remote_git() {
  git --git-dir "$REMOTE" "$@"
}

phase_0_commit() {
  remote_git log -1 --format=%H phase-0-foundations -- docs/help.png
}

pr_body() {
  jq -r '.[0].body' "$FAKE_STATE/prs.json"
}

pr_summary() {
  pr_body | awk '/^## Summary$/ { on = 1; next } /^## / { on = 0 } on'
}

release_job() {
  awk '/^jobs:$/ { on = 1; next } on && /^  [a-z-]+:$/ { sub(/^  /, ""); sub(/:$/, ""); print }' "$RECIPE/templates/.github/workflows/release.yml" | sed -n "$1p"
}

release_job_count() {
  awk '/^jobs:$/ { on = 1; next } on && /^  [a-z-]+:$/ { n++ } END { print n }' "$RECIPE/templates/.github/workflows/release.yml"
}

required_check() {
  jq -r --argjson i "$1" '.[0].rules[] | select(.type == "required_status_checks") | .parameters.required_status_checks[$i].context' "$FAKE_STATE/rulesets.json"
}

required_check_count() {
  jq -r '.[0].rules[] | select(.type == "required_status_checks") | .parameters.required_status_checks | length' "$FAKE_STATE/rulesets.json"
}

add_required_check_by_hand() {
  jq --arg c "$1" 'map(.rules |= map(if .type == "required_status_checks" then .parameters.required_status_checks += [{context: $c}] else . end))' "$FAKE_STATE/rulesets.json" >"$SCRATCH/rulesets.json"
  mv "$SCRATCH/rulesets.json" "$FAKE_STATE/rulesets.json"
}

remove_required_check_by_hand() {
  jq --arg c "$1" 'map(.rules |= map(if .type == "required_status_checks" then .parameters.required_status_checks |= map(select(.context != $c)) else . end))' "$FAKE_STATE/rulesets.json" >"$SCRATCH/rulesets.json"
  mv "$SCRATCH/rulesets.json" "$FAKE_STATE/rulesets.json"
}

label_field() {
  jq -r --arg n "$1" --arg f "$2" '.[] | select(.name == $n) | .[$f]' "$FAKE_STATE/labels.json"
}

mutating_calls() {
  grep -E -- '-X (POST|PATCH|PUT|DELETE)|^gh (repo create|label create|pr create|pr edit|secret set)' "$FAKE_LOG" || true
}

merge_phase_0() {
  remote_git update-ref refs/heads/main refs/heads/phase-0-foundations
  remote_git update-ref -d refs/heads/phase-0-foundations
  jq 'map(.state = "MERGED")' "$FAKE_STATE/prs.json" >"$SCRATCH/prs.json"
  mv "$SCRATCH/prs.json" "$FAKE_STATE/prs.json"
}

reject_branch_pushes() {
  export FAKE_REJECT_BRANCH=phase-0-foundations
}

allow_branch_pushes() {
  touch "$FAKE_STATE/allow-branch-pushes"
}

tap_block() {
  cat <<'EOF'
Before merging the pull request, set TAP_TOKEN (the release needs it to write the Homebrew formula):

1. Create the token: https://github.com/settings/personal-access-tokens/new?name=acme-tool-tap&contents=write
   Repository access: Only select repositories → homebrew-tap. Permission: Contents → Read and write.
2. Copy the token, then run:
   pbpaste | gh secret set TAP_TOKEN --repo acme/acme-tool
EOF
}

interrupt_render_after() {
  local wt="$PROJECT/.claude/worktrees/phase-0-foundations" total keep
  set +e
  FAKE_CHROME_FAIL=1 flow >/dev/null 2>&1
  set -e
  total="$(template_file_count)"
  keep=$((total * $1 / $2))
  (cd "$RECIPE/templates" && find . -type f | sed 's|^\./||' | LC_ALL=C sort) | tail -n +$((keep + 1)) >"$SCRATCH/cut"
  while IFS= read -r rel; do
    if git -C "$wt" cat-file -e "origin/main:$rel" 2>/dev/null; then
      git -C "$wt" checkout -q origin/main -- "$rel"
    else
      rm "$wt/$rel"
    fi
  done <"$SCRATCH/cut"
}

template_file_count() {
  find "$RECIPE/templates" -type f | wc -l | tr -d ' '
}

shipped_file_count() {
  remote_git ls-tree -r --name-only "$(phase_0_commit)" | wc -l | tr -d ' '
}

half_bootstrap() {
  local reference="$SCRATCH/reference"
  set +e
  FAKE_GH_FAIL="repo create" flow >/dev/null 2>&1
  set -e
  cp -R "$PROJECT" "$reference"
  rm -rf "$PROJECT" "$reference/.git"
  mkdir "$PROJECT"
  [ "$1" -ge 1 ] || return 0
  mkdir -p "$PROJECT/.github/workflows"
  [ "$1" -ge 2 ] || return 0
  git -C "$PROJECT" init -q --initial-branch main
  [ "$1" -ge 3 ] || return 0
  git -C "$PROJECT" remote add origin git@github.com:acme/acme-tool.git
  [ "$1" -ge 4 ] || return 0
  cp "$reference/README.md" "$PROJECT/README.md"
  [ "$1" -ge 5 ] || return 0
  cp "$reference/LICENSE" "$PROJECT/LICENSE"
  [ "$1" -ge 6 ] || return 0
  cp "$reference/CHANGELOG.md" "$PROJECT/CHANGELOG.md"
  [ "$1" -ge 7 ] || return 0
  cp "$reference/.github/workflows/ci.yml" "$PROJECT/.github/workflows/ci.yml"
  [ "$1" -ge 8 ] || return 0
  git -C "$PROJECT" add -A
}
