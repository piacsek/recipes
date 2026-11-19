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
pull request link, a reminder to rerun after the merge to require the remaining checks (while the
scaffold is not on `main`) and the `TAP_TOKEN` instructions.

| Input | Flag | Environment | Default |
| --- | --- | --- | --- |
| Name | first argument | `TUI_REPO_NAME` | asked |
| Description | `--description` | `TUI_REPO_DESCRIPTION` | asked |
| GitHub owner | `--owner` | `TUI_REPO_OWNER` | `gh api user` |
| Tap repository | `--tap` | `TUI_REPO_TAP` | `<owner>/homebrew-tap` (the part after `homebrew-` takes letters, digits, `-` and `_`, no `.`) |
| LICENSE author | `--author` | `TUI_REPO_AUTHOR` | `git config user.name` |
| Skip the confirmation | `--yes` | `TUI_REPO_YES=1` | asks |
| Projects directory | | `PROJECTS_DIR` | `~/projects` |
| Shared denylist | | `TUI_REPO_SHARED_DENYLIST` | `~/.config/conveyor-dev/denylist` |
| Chrome binary | | `CHROME` | Google Chrome, then `google-chrome`, then `chromium` |

Every path the script is given (`PROJECTS_DIR`, `TUI_REPO_SHARED_DENYLIST`, `--render-only`,
`CHROME`, `TMPDIR` and `HOME`) is made absolute from the current directory once, before anything
is checked, so a relative path behaves exactly as its absolute form.

`--render-only <empty dir>` renders the template there (and runs `cargo fmt`) without touching git,
GitHub or `~/.config`.

The name gives three variants: `acme_tool` (Rust identifiers), `ACME_TOOL` (the denylist variable)
and `AcmeTool` (the Homebrew formula class). It must start with a lowercase letter, hold only
lowercase letters, digits and single hyphens, stay within 64 characters and not be a Rust keyword, a
name cargo or Windows refuses, or the name of any package in the template's `Cargo.lock` (read at
run time; two packages of one name break the release scripts), and not be a bash keyword or builtin
(`case`, `echo`, `cd`: the rendered scripts would run the builtin instead). Test helpers and constants have fixed names
(`launch`, `PACKAGE_ENTRY`, `link_dev_binary`), so a name such as `stdout`, `stderr`,
`version-line` or `ls` is accepted.

Every input is checked before anything is created. Before the first side effect it also checks that
the shared denylist is a readable, non-empty file (when the project's link is missing) and, while phase 0 is still to do,
that `tmux`, `freeze`, Chrome or chromium, `python3` and `cargo` are installed, one line per missing
tool with how to install it. It looks the tap repository up once (read only) and stops when it does
not exist or when it cannot find out.

The name, description, owner, tap and author are matched against the denylist (the project's
`~/.config/<name>-dev/denylist` when it exists, else the shared one), case-insensitively, ignoring
blank lines. Each input that matches is named and the run stops; the list and the matching line are
never printed. An existing `~/.config/<name>-dev/denylist` must resolve to a readable, non-empty
file, and the run says it does.

Before asking `Go ahead?`, the script prints the name, description, owner, tap and author it
resolved, then each step with what it would do.

Every probe of GitHub or git tells "confirmed absent" (a 404, an unset origin) from "could not find
out" (any other failure). The second stops the run, naming what it could not find out, before
anything changes.

## Steps

| Step | Done when |
| --- | --- |
| denylist link | `~/.config/<name>-dev/denylist` exists (a file of your own is kept) |
| local repository | `~/projects/<name>` is a git repository with a commit |
| GitHub repository | `<owner>/<name>` exists |
| push main | the GitHub repository has any branch (`main` is pushed only into one with none) |
| repository settings | squash only, delete merged branches, discussions, secret scanning and push protection are already set |
| Actions token permissions | read only, no pull request approval |
| main ruleset | a branch ruleset of this repository targets `main` and, once the scaffold is on `main`, requires `check`, `audit` and `version` |
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
nothing to do. A step the plan said would run that turns out done when its turn comes means
something changed it meanwhile: the run stops and names the step. Rerunning after a failure finishes the job; rerunning on a finished project changes
nothing and exits 0.

- An existing `<owner>/<name>` is taken over only when this recipe started it: it has no branch,
  or its default branch is `main` and `main` holds exactly the bootstrap or the scaffold
  (`scripts/ship.sh` and `plans/phase-0-foundations.md`). The older bootstrap without
  `CHANGELOG.md` is accepted only once phase 0 exists for it (its branch on GitHub or a pull
  request), so every phase 0 step is skipped. Anything else stops the run in the preflight, before
  the plan, with one line saying what was found.
- An existing `~/projects/<name>` is fine when it is a clone of `<owner>/<name>` (origin
  `git@github.com:<owner>/<name>.git` or its https form). Anything else stops the run before any
  side effect.
- An interrupted first local setup is finished: a `~/projects/<name>` that holds only what the
  bootstrap writes (its directories, files byte-identical to the bootstrap's, and a `.git` with no
  commit whose origin is unset or `<owner>/<name>`) is completed. A changed or extra file, another
  origin or a commit stops the run.
- The ruleset is found by what it protects: a ruleset whose source is this repository, whose target
  is `branch` and whose conditions include `~DEFAULT_BRANCH`, `~ALL`, `refs/heads/main`,
  `refs/heads/*` or `refs/heads/**`, whatever its name. The listing is read page by page. A matching
  ruleset whose enforcement is not `active` is left as is, and the plan and the closing lines say so.
  A matching ruleset that includes `~ALL`, `refs/heads/*` or `refs/heads/**` covers every branch:
  requiring `check` and `audit` there would refuse the first push of `phase-0-foundations`, so no
  check is added, and the plan, the closing lines and the phase 0 plan's facts say so. It is created only when none matches and never replaced; when more than one matches, the
  run names them and stops before any change.
  A rerun adds whichever of `check` and `audit` is missing, and, once `main` holds
  `scripts/ship.sh`, `version`, after the checks already there, and says what it added. It never
  removes or reorders a check.
- Labels are created when missing (compared case-insensitively, as GitHub does) and never changed.
- Phase 0 is left alone when the branch is on GitHub but not in your worktree, a pull request for it
  exists in any state, `main` holds `scripts/ship.sh`, or the local branch holds work of its own.
- A half-way local branch is finished: its worktree exists and it is either level with
  `origin/main` (the render or the screenshot failed) or one commit ahead with the phase 0 title as
  its subject (the push or the pull request failed). The rerun renders, shoots, ships or opens the
  pull request from where it stopped.
- Before it ships from the worktree (the phase 0 commit or the metrics row), the script requires
  `phase-0-foundations` to be checked out there and the worktree to hold nothing but its own change.
  Anything else stops the run and names the paths, since `scripts/ship.sh` commits every change.
- The render goes to a fresh temporary directory first and is compared with the worktree. Files
  that already match are kept, missing or partial ones are copied in, and the render step counts as
  done only when every rendered file matches. A worktree change the render would not write (an
  untracked file, an edit to a tracked or rendered file, or a file at a rendered path that git does
  not track, ignored ones included) stops the run and names its paths. The
  fresh render is formatted with `cargo fmt` first, so it equals what `scripts/ship.sh` formats.
- `tests/flow_test.sh` fails every side-effecting step once and, separately, kills the script right
  after it, then checks that a rerun ends in the same state as an uninterrupted run.
- A branch on GitHub with no pull request and no local branch is left alone, and the closing lines
  print the commands that open its pull request.

## Owner steps

1. Run `tui_repo <name>` and read the pull request.
2. Before merging, set `TAP_TOKEN`: the release needs it to write the Homebrew formula. The script
   prints these steps last until the secret exists, then prints `TAP_TOKEN: already set`.
   1. Create a fine-grained token at
      `https://github.com/settings/personal-access-tokens/new?name=<name>-tap&contents=write`
      (plus `&target_name=<tap owner>` when the tap belongs to another account), with access to the
      tap repository only and Contents set to Read and write.
   2. Copy it, then run (`pbpaste` because the recipe targets the owner's Mac):

      ```bash
      pbpaste | gh secret set TAP_TOKEN --repo <owner>/<name>
      ```
3. Mark the pull request ready and merge it. The merge releases v0.0.1.
4. Rerun `tui_repo <name>` to require the remaining checks. It adds `version`, which can only be
   required once `main` runs it.

## Description characters

The description is copied literally into `Cargo.toml`, `flake.nix`, the usage text, the README and
the Homebrew formula. Characters that would change meaning in one of them are refused, not escaped.

| Characters | Rule |
| --- | --- |
| letters, digits, space, `& / \| , ( ) ! % ? ' # { } + - _ : ; = @ [ ] ^ ~ * .` | copied as they are |
| `<`, `>` | refused: Markdown in the README and the pull request body reads them as an HTML tag |
| `"` | refused: ends the string in TOML, Nix, Ruby and Rust |
| `\` | refused: starts an escape in TOML, Nix, Ruby, Rust and the formula's heredoc |
| `` ` `` | refused: runs a command in the formula's heredoc |
| `$` | refused: expands in the heredoc, and `${` interpolates in Nix |
| `#{`, `#@` | refused: Ruby interpolation |
| non-ASCII, tabs, control characters, line breaks | refused |
| first character | must be a capital letter (Homebrew's rule) |
| last character | no full stop, `?` or `!` (the README adds a full stop) and no space |
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

## Not yet proven against real GitHub

The fakes stand in for these; no test has run them against github.com:

- `gh label create` with an empty `--description` (for `adversarial-review-finding`).
- The ruleset `PUT` as sent, when a rerun adds a required check.
- The rerun after the phase 0 merge, which adds `version`.
- The interactive flow on a terminal: the questions and the `Go ahead? [y/N]` prompt.

## Known decisions

- The `/pr-review` link in the rendered guidelines is fixed to piacsek's dotfiles.
- An existing regular file at `~/.config/<name>-dev/denylist` is kept as that project's own list.
- The slow gates test uses the real Cargo and rustup caches and may fetch from crates.io; it never
  reaches GitHub or the real `~/.config`.
- A blank line in a denylist makes the rendered scrub check refuse every ship, which fails safe.
- The closing `TAP_TOKEN` instructions use `pbpaste`: the recipe targets the owner's Mac.
- Rulesets are recognised by the literal include patterns `~DEFAULT_BRANCH`, `~ALL`,
  `refs/heads/main`, `refs/heads/*` and `refs/heads/**`; excludes are not evaluated, so a ruleset
  that includes an all-branch pattern is left as is even when it excludes `phase-0-foundations`.
- The rendered `AGENTS.md` rule (the unsuffixed binary on PATH is the Homebrew release; never
  `cargo install` the crate into PATH) is for people developing the project, as in conveyor, and
  stands beside the README's source install for users.

## Bash

`tui_repo` runs on bash 3.2 (macOS `/bin/bash`) and newer, with BSD or GNU tools.
