const README: &str = include_str!("../README.md");

#[test]
fn the_readme_opens_with_the_name_and_the_one_line_description() {
    assert!(README.starts_with("# {{name}}\n\n{{description}}.\n\n## "));
}

#[test]
fn the_readme_has_exactly_the_three_user_sections_in_order() {
    let sections = sections();

    assert_eq!(sections.len(), 3, "{sections:?}");
    assert_eq!(sections[0], "## Installation");
    assert_eq!(sections[1], "## Usage");
    assert_eq!(sections[2], "## Development");
}

#[test]
fn the_readme_has_no_subsections() {
    assert!(!prose().iter().any(|line| line.starts_with("### ")));
}

#[test]
fn the_readme_names_one_h1() {
    assert_eq!(
        prose().iter().filter(|line| line.starts_with("# ")).count(),
        1
    );
}

#[test]
fn the_readme_installs_from_the_tap() {
    assert!(README.contains("\nbrew install {{tap}}/{{name}}\n"));
}

#[test]
fn the_readme_nix_install_works_without_the_experimental_features_enabled() {
    assert!(README.contains(
        "\nnix --extra-experimental-features 'nix-command flakes' profile install github:{{owner}}/{{name}}/stable\n"
    ));
}

#[test]
fn the_readme_usage_shows_the_version_flag() {
    assert!(README.contains("\n{{name}} --version"));
}

#[test]
fn the_readme_usage_shows_the_help_flag() {
    assert!(README.contains("\n{{name}} --help"));
}

#[test]
fn the_readme_builds_from_source_at_the_newest_release() {
    assert!(README.contains(
        "\ncargo install --git https://github.com/{{owner}}/{{name}} --branch stable --locked\n"
    ));
}

fn sections() -> Vec<&'static str> {
    prose()
        .into_iter()
        .filter(|line| line.starts_with("## "))
        .collect()
}

fn prose() -> Vec<&'static str> {
    let mut fenced = false;
    README
        .lines()
        .filter(|line| {
            if line.starts_with("```") {
                fenced = !fenced;
                return false;
            }
            !fenced
        })
        .collect()
}
