#!/usr/bin/env bash
# Print the Homebrew formula for a released version, fetching the asset hashes
# from the GitHub release. Usage: scripts/homebrew-formula.sh 0.1.0 > Formula/{{name}}.rb
set -euo pipefail

version="${1:?version without the leading v}"
base="https://github.com/{{owner}}/{{name}}/releases/download/v${version}"

sha() {
  curl -fsSL "${base}/{{name}}-$1.tar.gz.sha256" | cut -d' ' -f1
}

arm_mac="$(sha aarch64-apple-darwin)"
intel_mac="$(sha x86_64-apple-darwin)"
linux="$(sha x86_64-unknown-linux-gnu)"

cat <<FORMULA
class {{class}} < Formula
  desc "{{description}}"
  homepage "https://github.com/{{owner}}/{{name}}"
  license "MIT"

  on_macos do
    on_arm do
      url "${base}/{{name}}-aarch64-apple-darwin.tar.gz"
      sha256 "${arm_mac}"
    end
    on_intel do
      url "${base}/{{name}}-x86_64-apple-darwin.tar.gz"
      sha256 "${intel_mac}"
    end
  end

  on_linux do
    on_intel do
      url "${base}/{{name}}-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "${linux}"
    end
  end

  def install
    bin.install "{{name}}"
  end

  test do
    assert_equal "{{name}} #{version}\n", shell_output("#{bin}/{{name}} --version")
    assert_match "usage: {{name}}", shell_output("#{bin}/{{name}} bogus 2>&1", 1)
  end
end
FORMULA
