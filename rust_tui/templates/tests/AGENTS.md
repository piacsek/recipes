# tests

What has gone wrong in the tests before, and how the suites are set up to avoid it. Rules and
working agreements are in the root `AGENTS.md`. The traps below were hit in conveyor, where
these suites come from.

## Testing traps hit so far

- **`awk` is not the same program everywhere.** macOS ships BSD awk, the ubuntu runner's `awk`
  is `mawk`, and either may be `gawk` where someone installed it; BSD awk (version 20200816)
  and `mawk` count bytes, `gawk` in a UTF-8 locale counts characters, so in conveyor a script
  that measured `" → "` as 5 (its UTF-8 bytes) passed on one machine and failed on another. Measure a non-ASCII separator with `length()` and find it
  with `index()`, and before pushing a script that handles one, run its tests once with `gawk`
  first on `PATH` as `awk` and `LC_ALL=C.UTF-8`.
- **A scratch repository's `scripts/` are symlinks to the real scripts.** `link_script` links
  them, so a test that writes to one of those paths (`committed(&work, "scripts/<name>.sh", …)`)
  writes through the link and overwrites the tracked script in the worktree, and every later
  test runs the overwritten one. A test that needs a changed file under `scripts/` uses a name
  no test links.
- **Tests that write an executable and run it in the same test binary race on fork.** On Linux
  CI one test's `fs::write` was still open when another test's `Command` forked, the child
  inherited the fd and `exec` failed with `ExecutableFileBusy` ("Text file busy"); it never
  showed on macOS. `tests/scripts/` needs no mutex because it writes no executable: every shim
  is a symlink to a tracked script under `tests/fixtures/`, and the scripts under test are
  symlinked into the scratch directory. A new test that does write an executable takes a mutex
  shared by every such test for its whole body. Treat a green PR run as no proof against this
  class: it is timing-dependent.
- **A scratch `HOME` does not isolate what outranks it.** A variable exported in the shell wins
  over a scratch `HOME`: `{{upper}}_DENYLIST` names the real denylist whatever `HOME` is, and
  `GIT_DIR` or a global git config reaches into the scratch repository. The `ship.sh` and
  `scrub-check.sh` tests remove `{{upper}}_DENYLIST` next to their scratch `HOME`, and `isolated`
  (`tests/scripts/helpers.rs`) drops the git variables and configs; any new launcher that sets a
  scratch `HOME` removes what outranks it too.
