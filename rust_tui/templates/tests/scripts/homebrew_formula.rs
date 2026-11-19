use std::fs;
use std::os::unix::fs::symlink;
use std::path::Path;
use std::process::{Command, Output};

use crate::helpers::{calls, isolated, link_script, stdout, which};

#[test]
fn the_formula_is_the_{{snake}}_class_with_its_one_line_description() {
    let dir = tempfile::tempdir().unwrap();
    sandbox(dir.path());

    let output = homebrew_formula(dir.path());

    assert!(stdout(&output).starts_with(
        "class {{class}} < Formula\n  desc \"{{description}}\"\n  homepage \"https://github.com/{{owner}}/{{name}}\"\n  license \"MIT\"\n"
    ));
}

#[test]
fn the_formula_depends_on_nothing() {
    let dir = tempfile::tempdir().unwrap();
    sandbox(dir.path());

    let output = homebrew_formula(dir.path());

    assert!(
        !stdout(&output).contains("depends_on"),
        "{}",
        stdout(&output)
    );
}

#[test]
fn each_tarball_is_pinned_to_the_hash_its_release_publishes() {
    let dir = tempfile::tempdir().unwrap();
    sandbox(dir.path());

    let output = homebrew_formula(dir.path());

    assert!(stdout(&output).contains(
        "      url \"https://github.com/{{owner}}/{{name}}/releases/download/v0.1.0/{{name}}-aarch64-apple-darwin.tar.gz\"\n      sha256 \"arm\"\n"
    ));
    assert!(stdout(&output).contains(
        "      url \"https://github.com/{{owner}}/{{name}}/releases/download/v0.1.0/{{name}}-x86_64-apple-darwin.tar.gz\"\n      sha256 \"intel\"\n"
    ));
    assert!(stdout(&output).contains(
        "      url \"https://github.com/{{owner}}/{{name}}/releases/download/v0.1.0/{{name}}-x86_64-unknown-linux-gnu.tar.gz\"\n      sha256 \"linux\"\n"
    ));
}

#[test]
fn the_hashes_are_fetched_from_the_release_of_that_version() {
    let dir = tempfile::tempdir().unwrap();
    sandbox(dir.path());

    homebrew_formula(dir.path());

    let calls = calls(dir.path());
    assert_eq!(calls.len(), 3);
    assert_eq!(
        calls[0],
        "curl -fsSL https://github.com/{{owner}}/{{name}}/releases/download/v0.1.0/{{name}}-aarch64-apple-darwin.tar.gz.sha256"
    );
    assert_eq!(
        calls[1],
        "curl -fsSL https://github.com/{{owner}}/{{name}}/releases/download/v0.1.0/{{name}}-x86_64-apple-darwin.tar.gz.sha256"
    );
    assert_eq!(
        calls[2],
        "curl -fsSL https://github.com/{{owner}}/{{name}}/releases/download/v0.1.0/{{name}}-x86_64-unknown-linux-gnu.tar.gz.sha256"
    );
}

#[test]
fn the_formula_installs_the_{{snake}}_binary() {
    let dir = tempfile::tempdir().unwrap();
    sandbox(dir.path());

    let output = homebrew_formula(dir.path());

    assert!(stdout(&output).contains("  def install\n    bin.install \"{{name}}\"\n  end\n"));
}

#[test]
fn the_formula_test_checks_only_the_version_and_the_usage_on_an_unknown_argument() {
    let dir = tempfile::tempdir().unwrap();
    sandbox(dir.path());

    let output = homebrew_formula(dir.path());

    assert!(stdout(&output).ends_with(
        "  test do\n    assert_equal \"{{name}} #{version}\\n\", shell_output(\"#{bin}/{{name}} --version\")\n    assert_match \"usage: {{name}}\", shell_output(\"#{bin}/{{name}} bogus 2>&1\", 1)\n  end\nend\n"
    ), "{}", stdout(&output));
}

#[test]
fn a_hash_that_cannot_be_fetched_stops_the_script() {
    let dir = tempfile::tempdir().unwrap();
    sandbox(dir.path());

    let output = homebrew_formula_where(
        dir.path(),
        "-fsSL https://github.com/{{owner}}/{{name}}/releases/download/v0.1.0/{{name}}-x86_64-apple-darwin",
    );

    assert_eq!(output.status.code(), Some(1));
    assert_eq!(stdout(&output), "");
}

fn homebrew_formula(root: &Path) -> Output {
    homebrew_formula_where(root, "no call fails")
}

fn homebrew_formula_where(root: &Path, failing_call: &str) -> Output {
    let mut path = vec![root.join("bin")];
    path.extend(std::env::split_paths(&std::env::var_os("PATH").unwrap()));
    isolated(&mut Command::new(which("bash")))
        .arg(root.join("work/scripts/homebrew-formula.sh"))
        .arg("0.1.0")
        .current_dir(root.join("work"))
        .env("PATH", std::env::join_paths(path).unwrap())
        .env("CALLS_LOG", root.join("calls.log"))
        .env("REPLIES", root.join("replies"))
        .env("FAILING_CALL", failing_call)
        .output()
        .unwrap()
}

fn sandbox(root: &Path) {
    link_script(&root.join("work"), "homebrew-formula.sh");
    fs::create_dir_all(root.join("bin")).unwrap();
    fs::create_dir_all(root.join("replies")).unwrap();
    fs::write(
        root.join("replies/{{name}}-aarch64-apple-darwin.tar.gz.sha256"),
        "arm  {{name}}-aarch64-apple-darwin.tar.gz\n",
    )
    .unwrap();
    fs::write(
        root.join("replies/{{name}}-x86_64-apple-darwin.tar.gz.sha256"),
        "intel  {{name}}-x86_64-apple-darwin.tar.gz\n",
    )
    .unwrap();
    fs::write(
        root.join("replies/{{name}}-x86_64-unknown-linux-gnu.tar.gz.sha256"),
        "linux  {{name}}-x86_64-unknown-linux-gnu.tar.gz\n",
    )
    .unwrap();
    symlink(
        Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/fixtures/reply-call.sh"),
        root.join("bin/curl"),
    )
    .unwrap();
}
