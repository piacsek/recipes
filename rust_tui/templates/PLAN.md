# {{name}} plan

The index of phases and the backlog. Each phase's plan, outcome and hurdles live in its own
file under `plans/`; its time and tokens are a row of [`plans/metrics.md`](plans/metrics.md).

## Phases

| Phase | Plan | Release |
| --- | --- | --- |
| 0 | [the foundations, scaffolded from the `rust_tui` recipe](plans/phase-0-foundations.md) | |

## Backlog

### Bring from conveyor when the interface exists

These parts of conveyor need a product to show or drive, so phase 0 left them out. Bring each
over, renamed and with its tests, in the phase that gives {{name}} that interface.

- The `details` shot of the screenshot script, from a demo mode, and `docs/details.png` in the
  README with the `tests/readme.rs` pin of it.
- The adversarial-review skill's `drive-demo.sh`, which drives the binary's demo under tmux.
- The README key-table pin in `tests/readme.rs`, once {{name}} has keys and a help view.
- `tests/stage_dispatch.rs`, once {{name}} has a dispatch to keep in one place.
- The tmux e2e plumbing: the `#[ignore]` tests that run the real binary in a scratch tmux server,
  `gates.sh` running them with `--include-ignored`, and `check` installing tmux.
