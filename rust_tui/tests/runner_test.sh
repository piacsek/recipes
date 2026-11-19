test_a_suite_of_passing_files_passes() {
  stub_suite
  set +e
  run_stub_suite >/dev/null 2>&1
  status=$?
  set -e
  assert_status "$status" 0
}

test_a_file_that_fails_to_source_fails_the_run() {
  stub_suite
  printf 'test_broken() {\n  ( echo open\n}\n' >"$STUB/render_test.sh"
  set +e
  run_stub_suite >/dev/null 2>&1
  status=$?
  set -e
  assert_status "$status" 1
}

test_a_file_that_fails_to_source_is_named() {
  stub_suite
  printf 'test_broken() {\n  ( echo open\n}\n' >"$STUB/render_test.sh"
  set +e
  output="$(run_stub_suite 2>&1)"
  set -e
  assert_contains "$output" "render_test.sh could not be sourced"
}

test_a_file_without_tests_fails_the_run() {
  stub_suite
  printf 'helper() {\n  :\n}\n' >"$STUB/render_test.sh"
  set +e
  output="$(run_stub_suite 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  assert_contains "$output" "render_test.sh holds no test"
}

test_a_missing_test_file_fails_the_run() {
  stub_suite
  rm "$STUB/render_test.sh"
  set +e
  output="$(run_stub_suite 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  assert_contains "$output" "render_test.sh is missing"
}

test_an_unexpected_test_file_fails_the_run() {
  stub_suite
  passing_file >"$STUB/extra_test.sh"
  set +e
  output="$(run_stub_suite 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  assert_contains "$output" "extra_test.sh is not in the expected list"
}

test_a_harness_tool_that_cannot_be_resolved_fails_the_run_before_any_test() {
  stub_suite
  set +e
  output="$(ORIGINAL_PATH="$SCRATCH/empty" run_stub_suite 2>&1)"
  status=$?
  set -e
  assert_status "$status" 1
  assert_contains "$output" "the test harness cannot find python3"
  refute_contains "$output" "passed, "
}

test_an_unresolved_python3_names_a_version_manager_shim_as_the_likely_cause() {
  stub_suite
  set +e
  output="$(ORIGINAL_PATH="$SCRATCH/empty" run_stub_suite 2>&1)"
  set -e
  assert_contains "$output" "a version-manager shim that fails outside your HOME"
}

stub_suite() {
  STUB="$SCRATCH/stub/tests"
  mkdir -p "$STUB" "$SCRATCH/empty"
  cp "$RECIPE/tests/run" "$RECIPE/tests/lib.sh" "$STUB/"
  for file in flow render runner slow_gates; do
    passing_file >"$STUB/${file}_test.sh"
  done
}

passing_file() {
  printf 'test_passes() {\n  assert_eq 1 1\n}\n'
}

run_stub_suite() {
  TESTS_JOBS=2 "$STUB/run" fast
}
