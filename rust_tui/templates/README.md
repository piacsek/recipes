# {{name}}

{{description}}.

## Installation

```sh
brew install {{tap}}/{{name}}
```

Or take a tarball from the [latest release](https://github.com/{{owner}}/{{name}}/releases/latest)
(macOS arm64 and x86_64, Linux x86_64; each has a `.sha256` and a build-provenance
attestation), or build the newest release from source with Rust 1.98+:

```sh
cargo install --git https://github.com/{{owner}}/{{name}} --branch stable --locked
```

Or with Nix (Linux, Apple silicon), from the `stable` branch, which follows the newest release:

```sh
nix --extra-experimental-features 'nix-command flakes' profile install github:{{owner}}/{{name}}/stable
```

## Usage

```sh
{{name}} --version   # or -V, or version
{{name}} --help      # or -h, or help
```

## Development

```sh
scripts/gates.sh          # scrub check, fmt, clippy, tests
scripts/dev-install.sh    # the working tree as ~/.local/bin/{{name}}-dev
scripts/ship.sh "message" # gates, dev-install, commit, push, draft PR
```

Guidelines live in `AGENTS.md`.
