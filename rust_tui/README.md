# rust_tui

`tui_repo` takes you from nothing to a public GitHub repository for a new Rust TUI, with its phase 0
draft pull request open: the gates, CI, the automatic release, the agent guidelines and the plans of
the template in `templates/` (which descends from conveyor), renamed for the new project. No agent
takes part.

## Command

```bash
rust_tui/tui_repo acme-tool --description "Keeps the acme fleet in line"
```

It prints what each step will do or skip, asks once, then runs the steps. The last lines are the
pull request link, a reminder to rerun after the merge (while the scaffold is not on `main`) and the
`TAP_TOKEN` instructions.

| Input | Flag | Environment | Default |
| --- | --- | --- | --- |
| Name | first argument | `TUI_REPO_NAME` | asked |
| Description | `--description` | `TUI_REPO_DESCRIPTION` | asked |
| GitHub owner | `--owner` | `TUI_REPO_OWNER` | `gh api user` |
| Tap repository | `--tap` | `TUI_REPO_TAP` | `<owner>/homebrew-tap` |
| LICENSE author | `--author` | `TUI_REPO_AUTHOR` | `git config user.name` |
| Skip the confirmation | `--yes` | `TUI_REPO_YES=1` | asks |
| Projects directory | | `PROJECTS_DIR` | `~/projects` |
| Shared denylist | | `TUI_REPO_SHARED_DENYLIST` | `~/.config/conveyor-dev/denylist` |
| Chrome binary | | `CHROME` | Google Chrome, then `google-chrome`, then `chromium` |

`--render-only <empty dir>` renders the template there (and runs `cargo fmt`) without touching git,
GitHub or `~/.config`.

The name gives three variants: `acme_tool` (Rust identifiers), `ACME_TOOL` (the denylist variable)
and `AcmeTool` (the Homebrew formula class). It must start with a lowercase letter, hold only
lowercase letters, digits and single hyphens, stay within 64 characters and not be a Rust keyword or
a name cargo or Windows refuses.

Every input is checked before anything is created. Before the first side effect it also checks that
the shared denylist exists (when the project's link is missing) and, while phase 0 is still to do,
that `tmux`, `freeze`, Chrome or chromium, `python3` and `cargo` are installed, one line per missing
tool with how to install it.

## Steps

| Step | Done when |
| --- | --- |
| denylist link | `~/.config/<name>-dev/denylist` exists (a file of your own is kept) |
| local repository | `~/projects/<name>` is a git repository with a commit |
| GitHub repository | `<owner>/<name>` exists |
| push main | `main` is on GitHub |
| repository settings | squash only, delete merged branches, discussions, secret scanning and push protection are already set |
| Actions token permissions | read only, no pull request approval |
| main ruleset | a ruleset named `main` exists and, once the scaffold is on `main`, requires `check`, `audit` and `version` |
| labels | `adversarial-review-finding`, `development-cycle-improvement` and `Type: Maintenance` exist |
| phase 0 worktree | `.claude/worktrees/phase-0-foundations` exists |
| phase 0 render | the branch has its commit, or the worktree holds the render |
| help screenshot | the branch has its commit, or `docs/help.png` exists |
| phase 0 pull request | a pull request for `phase-0-foundations` exists in any state |
| pull request body | the body is no longer the empty template |
| pull request in the metrics | `plans/metrics.md` on the branch names the pull request |

The bootstrap commit on `main` holds `README.md`, `LICENSE` (MIT), a `CHANGELOG.md` of its heading
alone and a `ci.yml` whose `check` job only echoes. Phase 0 is rendered in the worktree, off
`origin/main` with no upstream, and shipped with the rendered `scripts/ship.sh`, which runs the
gates and opens the draft pull request assigned to you. The script then writes the body (summary,
changes, the help screenshot pinned to its commit, the release diagram) and ships the metrics row
as a second commit. It never merges and never marks the pull request ready.

## Idempotency

Every step checks the real state first and prints `==> <step>: already done, skipped` when there is
nothing to do. Rerunning after a failure finishes the job; rerunning on a finished project changes
nothing and exits 0.

- An existing `~/projects/<name>` is fine when it is a clone of `<owner>/<name>` (origin
  `git@github.com:<owner>/<name>.git` or its https form). Anything else stops the run before any
  side effect.
- The ruleset is found by name and created only when missing. It is never replaced or duplicated.
  Once `main` holds `scripts/ship.sh`, a rerun adds whichever of `check`, `audit` and `version` is
  missing, after the checks already there, and says what it added. It never removes or reorders a
  check.
- Labels are created when missing and never changed.
- Phase 0 is left alone when the branch is on GitHub but not in your worktree, a pull request for it
  exists in any state, `main` holds `scripts/ship.sh`, or the local branch holds work of its own.
- A half-way local branch is finished: its worktree exists and it is either level with
  `origin/main` (the render or the screenshot failed) or one commit ahead with the phase 0 title as
  its subject (the push or the pull request failed). The rerun renders, shoots, ships or opens the
  pull request from where it stopped.

## Owner steps

1. Run `tui_repo <name>` and read the pull request.
2. Before merging, set `TAP_TOKEN`: the release needs it to write the Homebrew formula. The script
   prints these steps last until the secret exists, then prints `TAP_TOKEN: already set`.
   1. Create a fine-grained token at
      `https://github.com/settings/personal-access-tokens/new?name=<name>-tap&contents=write`,
      with access to the tap repository only and Contents set to Read and write.
   2. Copy it, then run:

      ```bash
      pbpaste | gh secret set TAP_TOKEN --repo <owner>/<name>
      ```
3. Mark the pull request ready and merge it. The merge releases v0.0.1.
4. Rerun `tui_repo <name>`. It adds `version` to the required checks, which can only be required
   once `main` runs it.

## Description characters

The description is copied literally into `Cargo.toml`, `flake.nix`, the usage text, the README and
the Homebrew formula. Characters that would change meaning in one of them are refused, not escaped.

| Characters | Rule |
| --- | --- |
| letters, digits, space, `& / \| , ( ) ! % ? ' # { } + - _ : ; < > = @ [ ] ^ ~ * .` | copied as they are |
| `"` | refused: ends the string in TOML, Nix, Ruby and Rust |
| `\` | refused: starts an escape in TOML, Nix, Ruby, Rust and the formula's heredoc |
| `` ` `` | refused: runs a command in the formula's heredoc |
| `$` | refused: expands in the heredoc, and `${` interpolates in Nix |
| `#{`, `#@` | refused: Ruby interpolation |
| non-ASCII, tabs, control characters, line breaks | refused |
| first character | must be a capital letter (Homebrew's rule) |
| last character | no full stop (the README adds one) and no space |
| length | at most 80 (Homebrew's limit) |

## Tests

```bash
rust_tui/tests/run
rust_tui/tests/run shellcheck
rust_tui/tests/run gates
```

The first runs the fast tests (the render and the whole flow against fakes), the second shellcheck,
the third renders a project and runs its own gates (cargo, minutes). `tests/run flow test_<name>`
runs one test. No test reaches GitHub or the network or touches the real `~/.config`: each test gets
a scratch `HOME`, and `tests/fakes/` stands in for `gh`, `cargo`, `tmux`, `freeze`, Chrome and
`sleep` (the fake `gh` keeps its repositories as bare git remotes in the scratch directory). Tests
are red first, assert one thing per line, and keep their helpers at the bottom of the file.

## Bash

`tui_repo` runs on bash 3.2 (macOS `/bin/bash`) and newer, with BSD or GNU tools.
