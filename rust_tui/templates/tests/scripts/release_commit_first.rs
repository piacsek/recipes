use std::fs;
use std::path::{Path, PathBuf};

use crate::helpers::{fragment, git, link_script, repository, stderr};
use crate::release_commit::{release_commit, today, CARGO_LOCK, CARGO_TOML, {{upper}}_ENTRY};

#[test]
fn the_first_release_writes_a_changelog_of_its_own_section_alone() {
    let dir = tempfile::tempdir().unwrap();
    let work = first_release_sandbox(dir.path());
    fragment(&work, "topic", "kind: feat\n\n- A first key.\n");

    let output = release_commit(&work, &["0.1.0"]);

    assert_eq!(output.status.code(), Some(0), "{}", stderr(&output));
    assert_eq!(
        fs::read_to_string(work.join("CHANGELOG.md")).unwrap(),
        format!("# Changelog\n\n## v0.1.0 ({})\n- A first key.\n", today())
    );
}

#[test]
fn the_first_release_sets_the_package_version() {
    let dir = tempfile::tempdir().unwrap();
    let work = first_release_sandbox(dir.path());
    fragment(&work, "topic", "kind: feat\n\n- A first key.\n");

    let output = release_commit(&work, &["0.1.0"]);

    assert_eq!(output.status.code(), Some(0), "{}", stderr(&output));
    assert_eq!(
        fs::read_to_string(work.join("Cargo.toml")).unwrap(),
        CARGO_TOML.replacen("0.3.1", "0.1.0", 1)
    );
}

#[test]
fn the_first_release_sets_the_version_of_the_{{snake}}_lock_entry() {
    let dir = tempfile::tempdir().unwrap();
    let work = first_release_sandbox(dir.path());
    fragment(&work, "topic", "kind: feat\n\n- A first key.\n");

    let output = release_commit(&work, &["0.1.0"]);

    assert_eq!(output.status.code(), Some(0), "{}", stderr(&output));
    assert_eq!(
        fs::read_to_string(work.join("Cargo.lock")).unwrap(),
        CARGO_LOCK.replacen({{upper}}_ENTRY, &{{upper}}_ENTRY.replace("0.3.1", "0.1.0"), 1)
    );
}

#[test]
fn the_first_release_must_be_above_zero() {
    let dir = tempfile::tempdir().unwrap();
    let work = first_release_sandbox(dir.path());
    fragment(&work, "topic", "kind: feat\n\n- A first key.\n");

    let output = release_commit(&work, &["0.0.0"]);

    assert_eq!(output.status.code(), Some(1));
    assert_eq!(
        stderr(&output),
        "0.0.0 is not above 0.0.0, where the first release counts from\n"
    );
}

#[test]
fn the_first_release_with_nothing_pending_is_refused() {
    let dir = tempfile::tempdir().unwrap();
    let work = first_release_sandbox(dir.path());

    let output = release_commit(&work, &["0.1.0"]);

    assert_eq!(output.status.code(), Some(1));
    assert_eq!(
        stderr(&output),
        "no fragment in changes/ is pending since the first commit; nothing to release\n"
    );
}

#[test]
fn the_second_release_keeps_the_first_from_its_tag_while_main_holds_the_heading_alone() {
    let dir = tempfile::tempdir().unwrap();
    let work = first_release_sandbox(dir.path());
    fragment(&work, "first", "kind: fix\n\n- Fixed the first thing.\n");
    let first = release_commit(&work, &["0.0.1"]);
    assert_eq!(first.status.code(), Some(0), "{}", stderr(&first));
    git(&work, &["commit", "-qam", "Release v0.0.1"]);
    git(&work, &["tag", "v0.0.1"]);
    git(&work, &["reset", "-q", "--hard", "HEAD~1"]);
    fragment(&work, "second", "kind: fix\n\n- Fixed the second thing.\n");

    let output = release_commit(&work, &["0.0.2"]);

    assert_eq!(output.status.code(), Some(0), "{}", stderr(&output));
    assert_eq!(
        fs::read_to_string(work.join("CHANGELOG.md")).unwrap(),
        format!(
            "# Changelog\n\n## v0.0.2 ({0})\n- Fixed the second thing.\n\n## v0.0.1 ({0})\n- Fixed the first thing.\n",
            today()
        )
    );
}

fn first_release_sandbox(root: &Path) -> PathBuf {
    let work = repository(root);
    link_script(&work, "fragments.sh");
    link_script(&work, "release-commit.sh");
    link_script(&work, "release-rewrite.sh");
    fs::write(work.join("CHANGELOG.md"), "# Changelog\n").unwrap();
    fs::write(
        work.join("Cargo.toml"),
        CARGO_TOML.replacen("0.3.1", "0.0.0", 1),
    )
    .unwrap();
    fs::write(
        work.join("Cargo.lock"),
        CARGO_LOCK.replacen({{upper}}_ENTRY, &{{upper}}_ENTRY.replace("0.3.1", "0.0.0"), 1),
    )
    .unwrap();
    git(&work, &["add", "-A"]);
    git(&work, &["commit", "-qm", "the foundations"]);
    work
}
