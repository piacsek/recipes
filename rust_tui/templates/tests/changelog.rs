use {{snake}}::changelog::{CHANGELOG, check, check_released};

#[test]
fn the_changelog_has_a_real_entry_for_the_crate_version() {
    assert_eq!(check(CHANGELOG, env!("CARGO_PKG_VERSION")), Ok(()));
}

#[test]
fn an_entry_without_bullets_is_refused() {
    let text = "# Changelog\n\n## v0.2.0 (2026-11-02)\n\n## v0.1.0 (2026-11-01)\n- first\n";

    assert_eq!(
        check(text, "0.2.0"),
        Err("v0.2.0 has no `- ` bullet".to_string())
    );
}

#[test]
fn a_version_without_an_entry_is_refused() {
    let text = "# Changelog\n\n## v0.1.0 (2026-11-01)\n- first\n";

    assert_eq!(
        check(text, "0.2.0"),
        Err("CHANGELOG.md has no entry for v0.2.0 at the top (found v0.1.0)".to_string())
    );
}

#[test]
fn a_header_only_changelog_has_no_entry_for_a_release() {
    assert_eq!(
        check("# Changelog\n", "0.0.1"),
        Err("CHANGELOG.md has no entry for v0.0.1 at the top (found vnone)".to_string())
    );
}

#[test]
fn a_header_only_changelog_is_a_build_from_main_before_the_first_release() {
    assert_eq!(check("# Changelog\n", "0.0.0"), Ok(()));
}

#[test]
fn a_bullet_copied_from_another_release_is_refused() {
    let text =
        "# Changelog\n\n## v0.2.0 (2026-11-02)\n- first\n\n## v0.1.0 (2026-11-01)\n- first\n";

    assert_eq!(
        check(text, "0.2.0"),
        Err("v0.2.0 repeats a bullet of v0.1.0: first".to_string())
    );
}

#[test]
fn versions_out_of_order_or_repeated_are_refused() {
    let text = "# Changelog\n\n## v0.10.0 (2026-11-03)\n- c\n\n## v0.9.0 (2026-11-02)\n- b\n\n## v0.9.0 (2026-11-01)\n- a\n";

    assert_eq!(
        check(text, "0.10.0"),
        Err("v0.9.0 is listed above v0.9.0; newest first, once each".to_string())
    );
}

#[test]
fn a_heading_without_a_date_is_refused() {
    let text = "# Changelog\n\n## v0.2.0\n- second\n\n## v0.1.0 (2026-11-01)\n- first\n";

    assert_eq!(
        check(text, "0.2.0"),
        Err("`## v0.2.0` must read `## vX.Y.Z (YYYY-MM-DD)`".to_string())
    );
}

#[test]
fn a_bullet_without_text_is_refused() {
    let text = "# Changelog\n\n## v0.2.0 (2026-11-02)\n- \n\n## v0.1.0 (2026-11-01)\n- first\n";

    assert_eq!(
        check(text, "0.2.0"),
        Err("v0.2.0 has no `- ` bullet".to_string())
    );
}

#[test]
fn a_bullet_continued_on_the_next_line_is_one_bullet() {
    let text = "# Changelog\n\n## v0.2.0 (2026-11-02)\n- Fixed\n  the queue refresh\n\n## v0.1.0 (2026-11-01)\n- Fixed\n  the build refresh\n";

    assert_eq!(check(text, "0.2.0"), Ok(()));
}

#[test]
fn a_second_level_heading_that_is_not_a_release_is_refused() {
    let text = "# Changelog\n\n## v0.21.0 (2026-11-02)\n\n## 0.20.0 (2026-11-02)\n- old\n";

    assert_eq!(
        check(text, "0.21.0"),
        Err("`## 0.20.0 (2026-11-02)` must read `## vX.Y.Z (YYYY-MM-DD)`".to_string())
    );
}

#[test]
fn a_released_version_without_its_entry_is_refused() {
    let text = "# Changelog\n\n## v0.21.0 (2026-11-02)\n- relabelled\n";

    assert_eq!(
        check_released(text, &["0.20.0", "0.21.0"], "0.21.0"),
        Err("v0.20.0 was released but has no entry; restore it, or merge origin/main if another branch released it".to_string())
    );
}

#[test]
fn every_released_tag_keeps_its_entry() {
    let mut args = vec!["tag", "--list", "v*"];
    if env!("CARGO_PKG_VERSION") == "0.0.0" {
        args.extend(["--merged", "HEAD"]);
    }
    let output = std::process::Command::new("git")
        .args(args)
        .current_dir(env!("CARGO_MANIFEST_DIR"))
        .output()
        .unwrap();
    let tags = String::from_utf8(output.stdout).unwrap();
    let released: Vec<&str> = tags
        .lines()
        .filter_map(|tag| tag.strip_prefix('v'))
        .collect();

    assert_eq!(
        check_released(CHANGELOG, &released, env!("CARGO_PKG_VERSION")),
        Ok(())
    );
}

#[test]
fn no_released_tag_asks_for_no_entry() {
    assert_eq!(check_released("# Changelog\n", &[], "0.0.0"), Ok(()));
}

#[test]
fn a_tag_newer_than_the_crate_version_is_not_required() {
    let text = "# Changelog\n\n## v0.20.0 (2026-11-02)\n- now\n";

    assert_eq!(
        check_released(text, &["0.20.0", "0.21.0"], "0.20.0"),
        Ok(())
    );
}

#[test]
fn a_date_that_is_not_on_the_calendar_is_refused() {
    let text =
        "# Changelog\n\n## v0.2.0 (2026-02-30)\n- second\n\n## v0.1.0 (2026-11-01)\n- first\n";

    assert_eq!(
        check(text, "0.2.0"),
        Err("`## v0.2.0 (2026-02-30)` must read `## vX.Y.Z (YYYY-MM-DD)`".to_string())
    );
}

#[test]
fn a_leap_day_is_a_date() {
    let text =
        "# Changelog\n\n## v0.2.0 (2028-02-29)\n- second\n\n## v0.1.0 (2026-11-01)\n- first\n";

    assert_eq!(check(text, "0.2.0"), Ok(()));
}

#[test]
fn a_leap_day_of_a_century_not_divisible_by_400_is_refused() {
    let text =
        "# Changelog\n\n## v0.2.0 (2100-02-29)\n- second\n\n## v0.1.0 (2026-11-01)\n- first\n";

    assert_eq!(
        check(text, "0.2.0"),
        Err("`## v0.2.0 (2100-02-29)` must read `## vX.Y.Z (YYYY-MM-DD)`".to_string())
    );
}

#[test]
fn a_leap_day_of_a_century_divisible_by_400_is_a_date() {
    let text =
        "# Changelog\n\n## v0.2.0 (2400-02-29)\n- second\n\n## v0.1.0 (2026-11-01)\n- first\n";

    assert_eq!(check(text, "0.2.0"), Ok(()));
}

#[test]
fn a_thirty_first_of_a_thirty_day_month_is_refused() {
    let text =
        "# Changelog\n\n## v0.2.0 (2026-04-31)\n- second\n\n## v0.1.0 (2026-11-01)\n- first\n";

    assert_eq!(
        check(text, "0.2.0"),
        Err("`## v0.2.0 (2026-04-31)` must read `## vX.Y.Z (YYYY-MM-DD)`".to_string())
    );
}

#[test]
fn a_thirteenth_month_is_refused() {
    let text =
        "# Changelog\n\n## v0.2.0 (2026-13-01)\n- second\n\n## v0.1.0 (2026-11-01)\n- first\n";

    assert_eq!(
        check(text, "0.2.0"),
        Err("`## v0.2.0 (2026-13-01)` must read `## vX.Y.Z (YYYY-MM-DD)`".to_string())
    );
}

#[test]
fn a_day_zero_is_refused() {
    let text =
        "# Changelog\n\n## v0.2.0 (2026-11-00)\n- second\n\n## v0.1.0 (2026-11-01)\n- first\n";

    assert_eq!(
        check(text, "0.2.0"),
        Err("`## v0.2.0 (2026-11-00)` must read `## vX.Y.Z (YYYY-MM-DD)`".to_string())
    );
}

#[test]
fn a_date_with_a_padded_month_is_refused() {
    let text =
        "# Changelog\n\n## v0.2.0 (2026- 2-03)\n- second\n\n## v0.1.0 (2026-11-01)\n- first\n";

    assert_eq!(
        check(text, "0.2.0"),
        Err("`## v0.2.0 (2026- 2-03)` must read `## vX.Y.Z (YYYY-MM-DD)`".to_string())
    );
}

#[test]
fn a_signed_year_is_refused() {
    let text =
        "# Changelog\n\n## v0.2.0 (+202-11-01)\n- second\n\n## v0.1.0 (2026-11-01)\n- first\n";

    assert_eq!(
        check(text, "0.2.0"),
        Err("`## v0.2.0 (+202-11-01)` must read `## vX.Y.Z (YYYY-MM-DD)`".to_string())
    );
}

#[test]
fn a_build_from_main_at_version_0_0_0_needs_no_entry_for_its_version() {
    let text =
        "# Changelog\n\n## v0.2.0 (2026-11-02)\n- second\n\n## v0.1.0 (2026-11-01)\n- first\n";

    assert_eq!(check(text, "0.0.0"), Ok(()));
}

#[test]
fn a_build_from_main_at_version_0_0_0_still_refuses_a_heading_without_a_date() {
    let text = "# Changelog\n\n## v0.2.0\n- second\n\n## v0.1.0 (2026-11-01)\n- first\n";

    assert_eq!(
        check(text, "0.0.0"),
        Err("`## v0.2.0` must read `## vX.Y.Z (YYYY-MM-DD)`".to_string())
    );
}

#[test]
fn a_build_from_main_at_version_0_0_0_asks_for_every_released_tag_it_is_given() {
    let text = "# Changelog\n\n## v0.21.0 (2026-11-02)\n- relabelled\n";

    assert_eq!(
        check_released(text, &["0.20.0", "0.21.0"], "0.0.0"),
        Err("v0.20.0 was released but has no entry; restore it, or merge origin/main if another branch released it".to_string())
    );
}
