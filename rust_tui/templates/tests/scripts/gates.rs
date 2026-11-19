use std::fs;
use std::os::unix::fs::symlink;
use std::path::{Path, PathBuf};
use std::process::{Command, Output};

use crate::helpers::{calls, git, link_script, recorder, repository, stderr, which};

#[test]
fn gates_run_every_test_in_one_pass() {
    let dir = tempfile::tempdir().unwrap();
    gates_sandbox(dir.path());

    let output = gates(dir.path());

    assert!(output.status.success(), "{}", stderr(&output));
    assert_eq!(calls(dir.path()).len(), 4);
    assert_eq!(calls(dir.path())[0], "scrub-check.sh ");
    assert_eq!(calls(dir.path())[1], "cargo fmt --check");
    assert_eq!(
        calls(dir.path())[2],
        "cargo clippy --all-targets -- -D warnings"
    );
    assert_eq!(calls(dir.path())[3], "cargo test");
}

#[test]
fn gates_on_a_branch_the_script_tests_do_not_read_run_every_other_test_target() {
    let dir = tempfile::tempdir().unwrap();
    gates_repository(dir.path());

    let output = repository_gates(dir.path(), None);

    assert!(output.status.success(), "{}", stderr(&output));
    assert_eq!(calls(dir.path()).len(), 5);
    assert_eq!(calls(dir.path())[0], "scrub-check.sh ");
    assert_eq!(calls(dir.path())[1], "cargo fmt --check");
    assert_eq!(
        calls(dir.path())[2],
        "cargo clippy --all-targets -- -D warnings"
    );
    assert_eq!(
        calls(dir.path())[3],
        "cargo test --lib --bins --test cli --test plans --test prs"
    );
    assert_eq!(calls(dir.path())[4], "cargo test --doc");
}

#[test]
fn gates_that_skip_the_script_tests_say_why_and_that_ci_runs_them() {
    let dir = tempfile::tempdir().unwrap();
    gates_repository(dir.path());

    let output = repository_gates(dir.path(), None);

    assert!(output.status.success(), "{}", stderr(&output));
    assert!(
        stderr(&output).contains(
            "==> skipping the script tests: nothing on this branch reaches the script tests; CI runs them\n"
        ),
        "{}",
        stderr(&output)
    );
}

#[test]
fn gates_on_a_branch_that_touches_a_script_run_every_test_in_one_pass() {
    let dir = tempfile::tempdir().unwrap();
    gates_repository(dir.path());
    fs::write(dir.path().join("work/scripts/another.sh"), "").unwrap();

    let output = repository_gates(dir.path(), None);

    assert!(output.status.success(), "{}", stderr(&output));
    assert_eq!(calls(dir.path()).len(), 4);
    assert_eq!(calls(dir.path())[0], "scrub-check.sh ");
    assert_eq!(calls(dir.path())[1], "cargo fmt --check");
    assert_eq!(
        calls(dir.path())[2],
        "cargo clippy --all-targets -- -D warnings"
    );
    assert_eq!(calls(dir.path())[3], "cargo test");
    assert!(
        !stderr(&output).contains("skipping the script tests"),
        "{}",
        stderr(&output)
    );
}

#[test]
fn gates_in_ci_never_skip_the_script_tests() {
    let dir = tempfile::tempdir().unwrap();
    gates_repository(dir.path());

    let output = repository_gates(dir.path(), Some("true"));

    assert!(output.status.success(), "{}", stderr(&output));
    assert_eq!(calls(dir.path()).len(), 4);
    assert_eq!(calls(dir.path())[0], "scrub-check.sh ");
    assert_eq!(calls(dir.path())[1], "cargo fmt --check");
    assert_eq!(
        calls(dir.path())[2],
        "cargo clippy --all-targets -- -D warnings"
    );
    assert_eq!(calls(dir.path())[3], "cargo test");
}

fn gates_sandbox(root: &Path) -> PathBuf {
    let bin = sandbox_bin(root);
    link_script(root, "gates.sh");
    link_script(root, "script-tests-skippable.sh");
    symlink(recorder(), root.join("scripts/scrub-check.sh")).unwrap();
    bin
}

fn gates(root: &Path) -> Output {
    Command::new(root.join("scripts/gates.sh"))
        .env_clear()
        .env("PATH", root.join("bin"))
        .env("CALLS_LOG", root.join("calls.log"))
        .env("GIT_CEILING_DIRECTORIES", root)
        .output()
        .unwrap()
}

fn gates_repository(root: &Path) -> PathBuf {
    let bin = sandbox_bin(root);
    let work = repository(root);
    link_script(&work, "gates.sh");
    link_script(&work, "script-tests-skippable.sh");
    symlink(recorder(), work.join("scripts/scrub-check.sh")).unwrap();
    for target in [
        "tests/cli.rs",
        "tests/plans.rs",
        "tests/prs/main.rs",
        "tests/scripts/main.rs",
        "tests/support/mod.rs",
        "tests/fixtures/prs.json",
    ] {
        let file = work.join(target);
        fs::create_dir_all(file.parent().unwrap()).unwrap();
        fs::write(file, "").unwrap();
    }
    git(&work, &["add", "-A"]);
    git(&work, &["commit", "-qm", "the gates"]);
    git(&work, &["update-ref", "refs/remotes/origin/main", "HEAD"]);
    fs::write(work.join("src/main.rs"), "fn main() { }\n").unwrap();
    bin
}

fn repository_gates(root: &Path, ci: Option<&str>) -> Output {
    let mut command = Command::new(root.join("work/scripts/gates.sh"));
    command
        .env_clear()
        .env("PATH", root.join("bin"))
        .env("CALLS_LOG", root.join("calls.log"))
        .env("GIT_CONFIG_GLOBAL", "/dev/null")
        .env("GIT_CONFIG_NOSYSTEM", "1")
        .env("GIT_CEILING_DIRECTORIES", root);
    if let Some(value) = ci {
        command.env("CI", value);
    }
    command.output().unwrap()
}

fn sandbox_bin(root: &Path) -> PathBuf {
    let bin = root.join("bin");
    fs::create_dir_all(&bin).unwrap();
    for program in ["bash", "dirname", "git", "grep", "sed"] {
        symlink(which(program), bin.join(program)).unwrap();
    }
    symlink(recorder(), bin.join("cargo")).unwrap();
    bin
}
