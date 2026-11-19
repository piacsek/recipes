#!/usr/bin/env bash
# Build the release binary and expose it as `{{name}}-dev`, separate from the Homebrew `{{name}}`.
set -euo pipefail
cd "$(dirname "$0")/.."
cargo build --release --locked
mkdir -p ~/.local/bin
ln -sfn "$PWD/target/release/{{name}}" ~/.local/bin/{{name}}-dev
echo "{{name}}-dev -> $PWD/target/release/{{name}}"
