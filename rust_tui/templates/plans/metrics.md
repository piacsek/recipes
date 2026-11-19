# Time and tokens per phase

One row per phase, from phase 0. Times are UTC. Each token figure says where it came from:
`measured` is the `subagent_tokens` of an agent's completion notice (not a running total across
resumes: in an earlier project a resumed builder's second notice was lower than its first; whether cached
input counts like fresh input is not known), `estimated` names its source, and
what nobody can read is `unknown`. The builder writes its row before `gh pr ready`; the ready,
merged and released cells cannot be known on the branch, so the next phase's first ship fills
them in from GitHub (see "Time and tokens" in `AGENTS.md`). `End` is the release, or the merge
with "no release" for a branch that feeds nothing into the binary.

| Phase | PR | Start | Draft PR | Clean review | Ready | Merged | Released | Start → end | Rounds | Builder | Claude reviewer | Codex reviewer | Orchestrator | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0 | {{pr_ref}} | {{start}} | {{draft_pr}} | no review | | | | | 0 | no agent | no agent | no agent | no agent | Rendered and shipped by the `tui_repo` script of the `rust_tui` recipe: no agent and no review round took part, so the token cells name no figure and there is no clean round. Start is the creation of the phase 0 worktree; start → end waits for the release. |
