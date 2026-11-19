use std::ffi::OsStr;
use std::os::unix::ffi::OsStrExt;
use std::process::{Command, Output};

#[test]
fn version_prints_the_crate_version_on_stdout() {
    assert_eq!(stdout(&{{snake}}(&["--version"])), version_line());
}

#[test]
fn version_exits_zero() {
    assert!({{snake}}(&["--version"]).status.success());
}

#[test]
fn the_short_version_flag_prints_the_crate_version() {
    assert_eq!(stdout(&{{snake}}(&["-V"])), version_line());
}

#[test]
fn the_short_version_flag_exits_zero() {
    assert!({{snake}}(&["-V"]).status.success());
}

#[test]
fn the_version_word_prints_the_crate_version() {
    assert_eq!(stdout(&{{snake}}(&["version"])), version_line());
}

#[test]
fn the_version_word_exits_zero() {
    assert!({{snake}}(&["version"]).status.success());
}

#[test]
fn version_writes_nothing_on_stderr() {
    assert!({{snake}}(&["--version"]).stderr.is_empty());
}

#[test]
fn help_prints_the_usage_on_stdout() {
    assert_eq!(stdout(&{{snake}}(&["--help"])), USAGE);
}

#[test]
fn help_exits_zero() {
    assert!({{snake}}(&["--help"]).status.success());
}

#[test]
fn the_short_help_flag_prints_the_usage() {
    assert_eq!(stdout(&{{snake}}(&["-h"])), USAGE);
}

#[test]
fn the_short_help_flag_exits_zero() {
    assert!({{snake}}(&["-h"]).status.success());
}

#[test]
fn the_help_word_prints_the_usage() {
    assert_eq!(stdout(&{{snake}}(&["help"])), USAGE);
}

#[test]
fn the_help_word_exits_zero() {
    assert!({{snake}}(&["help"]).status.success());
}

#[test]
fn help_writes_nothing_on_stderr() {
    assert!({{snake}}(&["--help"]).stderr.is_empty());
}

#[test]
fn an_unknown_argument_prints_the_usage_on_stderr() {
    assert_eq!(stderr(&{{snake}}(&["bogus"])), USAGE);
}

#[test]
fn an_unknown_argument_exits_one() {
    assert_eq!({{snake}}(&["bogus"]).status.code(), Some(1));
}

#[test]
fn an_unknown_argument_writes_nothing_on_stdout() {
    assert!({{snake}}(&["bogus"]).stdout.is_empty());
}

#[test]
fn no_argument_prints_the_usage_on_stderr() {
    assert_eq!(stderr(&{{snake}}(&[])), USAGE);
}

#[test]
fn no_argument_exits_one() {
    assert_eq!({{snake}}(&[]).status.code(), Some(1));
}

#[test]
fn a_second_argument_prints_the_usage_on_stderr() {
    assert_eq!(stderr(&{{snake}}(&["--version", "--help"])), USAGE);
}

#[test]
fn a_second_argument_exits_one() {
    assert_eq!({{snake}}(&["--version", "--help"]).status.code(), Some(1));
}

#[test]
fn a_non_utf8_argument_exits_one() {
    assert_eq!({{snake}}_with_bytes(b"\xff").status.code(), Some(1));
}

#[test]
fn a_non_utf8_argument_prints_the_usage_on_stderr() {
    assert_eq!(stderr(&{{snake}}_with_bytes(b"\xff")), USAGE);
}

#[test]
fn changelog_prints_the_bundled_changelog_on_stdout() {
    assert_eq!(
        stdout(&{{snake}}(&["changelog"])),
        include_str!("../CHANGELOG.md")
    );
}

#[test]
fn changelog_exits_zero() {
    assert!({{snake}}(&["changelog"]).status.success());
}

#[test]
fn changelog_writes_nothing_on_stderr() {
    assert!({{snake}}(&["changelog"]).stderr.is_empty());
}

const USAGE: &str =
    "{{name}}: {{description}}\n\nusage: {{name}} [--help | --version | changelog]\n";

fn version_line() -> String {
    format!("{{name}} {}\n", env!("CARGO_PKG_VERSION"))
}

fn {{snake}}(args: &[&str]) -> Output {
    Command::new(env!("CARGO_BIN_EXE_{{name}}"))
        .args(args)
        .output()
        .unwrap()
}

fn stdout(output: &Output) -> String {
    String::from_utf8_lossy(&output.stdout).into_owned()
}

fn stderr(output: &Output) -> String {
    String::from_utf8_lossy(&output.stderr).into_owned()
}

fn {{snake}}_with_bytes(arg: &[u8]) -> Output {
    Command::new(env!("CARGO_BIN_EXE_{{name}}"))
        .arg(OsStr::from_bytes(arg))
        .output()
        .unwrap()
}
