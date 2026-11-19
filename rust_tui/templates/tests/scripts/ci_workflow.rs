use std::fs;
use std::path::Path;

#[test]
fn the_check_job_runs_the_formatter_the_linter_and_every_test() {
    assert!(ci().contains(CHECK_JOB), "{}", ci());
}

#[test]
fn the_check_job_installs_nothing_beyond_the_toolchain() {
    assert!(!ci().contains("apt-get"), "{}", ci());
}

#[test]
fn the_audit_job_checks_the_lock_against_the_advisory_database() {
    assert!(ci().contains(AUDIT_JOB), "{}", ci());
}

fn ci() -> String {
    fs::read_to_string(Path::new(env!("CARGO_MANIFEST_DIR")).join(".github/workflows/ci.yml"))
        .unwrap()
}

const CHECK_JOB: &str = "  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09 # v5
        with:
          fetch-depth: 0
      - uses: dtolnay/rust-toolchain@d1031067263f94b142dd6c0ce24c5eb9d02d52a0 # master 2026-09
        with:
          toolchain: 1.98.1
          components: rustfmt, clippy
      - uses: Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2
      - run: cargo fmt --check
      - run: cargo clippy --locked --all-targets -- -D warnings
      - run: cargo test --locked
";

const AUDIT_JOB: &str = "  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09 # v5
";
