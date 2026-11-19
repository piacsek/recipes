use std::fs;
use std::path::Path;

#[test]
fn the_workflow_runs_when_a_pull_request_closes() {
    let workflow = workflow();

    assert!(workflow.contains("on:\n  pull_request_target:\n    types: [closed]\n"));
}

#[test]
fn only_an_unmerged_branch_of_this_repository_other_than_the_default_is_deleted() {
    let workflow = workflow();

    assert!(workflow.contains("!github.event.pull_request.merged &&\n"));
    assert!(
        workflow
            .contains("github.event.pull_request.head.repo.full_name == github.repository &&\n")
    );
    assert!(workflow.contains(
        "github.event.pull_request.head.ref != github.event.repository.default_branch\n"
    ));
}

#[test]
fn only_the_delete_job_may_write_and_no_secret_is_read() {
    let workflow = workflow();

    assert!(workflow.contains("permissions:\n  contents: read\n"));
    assert_eq!(workflow.matches("contents: write").count(), 1);
    assert!(!workflow.contains("secrets."));
}

#[test]
fn the_pull_request_is_never_checked_out() {
    let workflow = workflow();

    assert!(!workflow.contains("actions/checkout"));
}

#[test]
fn a_branch_with_another_open_pull_request_is_left_in_place() {
    let workflow = workflow();

    assert!(workflow.contains("still has an open pull request; left in place"));
}

#[test]
fn a_branch_pushed_after_the_close_is_left_in_place() {
    let workflow = workflow();

    assert!(workflow.contains("if [ \"$tip\" != \"$HEAD_SHA\" ]; then"));
    assert!(workflow.contains("--force-with-lease=\"$ref:$HEAD_SHA\" \":$ref\""));
}

fn workflow() -> String {
    fs::read_to_string(
        Path::new(env!("CARGO_MANIFEST_DIR")).join(".github/workflows/delete-closed-branch.yml"),
    )
    .unwrap()
}
