# Phase 0: the foundations, scaffolded from the `rust_tui` recipe

## Context

{{name}} starts as a public repository holding only its bootstrap commit. This phase renders the
template of the `rust_tui` recipe (which descends from conveyor, an earlier project by the
recipe's author) with everything that works without a product: the agent guidelines, the
guardrails, CI, and the automatic release that tags, builds, attests and publishes a binary, updates a
Homebrew formula and moves a `stable` branch for the Nix flake. The binary itself only answers
`--help`, `--version` and `changelog`; Phase 1 defines what {{name}} is.

## Verified facts ({{date}}, `main` at {{main_sha}})

Checked by `tui_repo` before it rendered this branch:

- `main` holds only the bootstrap commit: `README.md`, `LICENSE` (MIT), a `CHANGELOG.md` of its
  `# Changelog` heading alone and a `ci.yml` whose `check` job only echoes.
- The `main` ruleset (id {{ruleset_id}}) exists and requires `check` and `audit`.
- `~/.config/{{name}}-dev/denylist` exists on the machine that ran `tui_repo`, so the scrub check
  ran from the first ship of this branch.

## Decisions

- Same toolchain (1.98.1, edition 2024), lints and release profile as conveyor.
- The binary answers `--version`, `-V`, `version` (prints `{{name}} <version>`) and `--help`, `-h`,
  `help` (prints the usage) and `changelog` (prints the bundled `CHANGELOG.md`) on stdout with
  exit 0. Anything else, no argument included, prints the
  usage on stderr and exits 1. No dependency; `tempfile` and `toml` are dev-dependencies the tests
  use.
- Rules that start at a later phase in conveyor apply from phase 0 here. Sweeps stay at multiples of
  5; the first one opens phase 5.
- `main` carries a `CHANGELOG.md` of its `# Changelog` heading alone, from the bootstrap commit,
  as conveyor's `main` carries one frozen at its last hand-made entry. Each release commit, which
  lives only on its tag, writes the sections. The binary bundles the file, so the flake reads it.
  This pull request leaves it as `main` has it, so the version check, which refuses any change to
  `CHANGELOG.md`, passes.
- The changelog rules come from conveyor (`src/changelog.rs`, `tests/changelog.rs`) with the
  calendar check written out instead of the `chrono` dependency, and without the assertion that
  tags exist, since before the first release none do.

## The first release, from zero tags

Smallest design: no `vX.Y.Z` tag means "never released". The release counts from the empty tree
at version 0.0.0, and the released changelog is empty.

| Script | With no tag |
| --- | --- |
| `fragments.sh` `last_tag` | prints nothing and succeeds |
| `fragments.sh` `pending_fragments`, `refuse_edits` | diff from the empty tree: every fragment is pending, none was released |
| `fragments.sh` `refuse_repeats` | compares against no released bullet |
| `next-version.sh` | bumps from 0.0.0: a `feat` gives 0.1.0, a patch kind (`fix`, `internal`) 0.0.1 |
| `release-commit.sh` | the version must be above 0.0.0; `CHANGELOG.md` is the new section alone |
| `release-tag.sh` | no release to resume: goes straight to tagging what is pending |
| `version-check.sh` | no refusal for the missing tag; repeats are checked against nothing released |
| `release-unfinished.sh`, `releases.sh` | already answer `missing` for a release that does not exist |
| `previous-tag.sh` | already prints `previous_tag=` (empty) for the lowest tag |
| `formula-version.sh` | already reads a 404 as "no formula yet" and picks the newest complete release |
| `stable-version.sh` | already reads a 404 as "no stable branch yet" and picks the newest complete release |

A clone without its tags reads as "never released" too. The release and version workflows fetch
every `v*` tag before running the scripts, so only a local run can see that state.

## What the recipe ported from conveyor, adapted or left out

- Ported as is, renamed: the release, version, sweep, scrub, ship, dev-install and flake scripts
  with their script tests; the workflows; issue forms, PR template, CONTRIBUTING; the two skills;
  `scripts/truecolor.py` and the screenshot rules of the root `AGENTS.md`.
- Adapted: the root `AGENTS.md`, `.github/AGENTS.md` and `tests/AGENTS.md` keep the process
  rules and drop the product; the formula has no `depends_on "gh"` and tests only `--version` and
  an unknown argument; the meta-tests count phases from 0; `scripts/screenshots.sh` keeps
  conveyor's capture (tmux, `truecolor.py`, freeze, headless Chrome) and shoots one image,
  `docs/help.png`, of `{{name}} --help` instead of four views of a demo.
- Left out: conveyor's product code, product tests and fixtures, its plans, changelog, fragments
  and its four screenshots. What waits for an interface is listed in `PLAN.md` under "Bring
  from conveyor when the interface exists".

## Tasks

1. `tui_repo` creates this branch in its own worktree off `origin/main`, renders the recipe's
   template into it, runs `scripts/screenshots.sh` so `docs/help.png` is in the same commit, and
   ships it with `scripts/ship.sh`, which runs the gates and opens the draft pull request; it
   then fills the pull request body, which embeds the image.
2. A second ship writes the pull request's number and opening time into `plans/metrics.md`.

## Outcome

- {{name}} has conveyor's process and pipeline, renamed: gates, scrub check, ship, dev-install,
  the release queue (tag, build, attest, publish, tap, `stable`), the `version` check, the
  flake build, the sweep issue, branch cleanup, the two skills, the issue forms and the three
  `AGENTS.md` files. The binary answers `--help`, `--version` and `changelog` and nothing
  else.
- The screenshot rules hold from this phase: `docs/help.png` shows `{{name}} --help`, and the
  pull request body embeds it at the commit that holds it.
- The first release starts from zero tags: no tag reads as "never released", versions count
  from 0.0.0 and every fragment is pending. The table above is under "Releasing internals"
  in `.github/AGENTS.md`, each row with the test that proves it. This branch's fragment is
  `kind: fix` (a patch kind: `--help` and `--version` are observable, so not `internal`), so
  the merge releases v0.0.1.
- `version.yml` runs on `pull_request_target`, so it runs as `main` holds it and does not run on
  this pull request, which adds it. Its proof here is `scripts/version-check.sh origin/main HEAD`
  run locally before the pull request is marked ready.
- Not in conveyor's form: `gates.sh` runs no tmux e2e tests; `tests/dead_code.rs` allows
  `dead_code` nowhere, since there is no `tests/support/` module; the `check` job runs
  `cargo test --locked` without `--include-ignored`.
- Owner steps, outside this repository: before merging, set `TAP_TOKEN` (the merge starts the
  first release run, whose `tap` job fails without it); after merging, rerun `tui_repo {{name}}`,
  which adds `version` to the ruleset's required checks.
- Review: none. A script rendered a template that was reviewed where it came from; no agent took
  part in this phase.

## Hurdles

- none recorded
