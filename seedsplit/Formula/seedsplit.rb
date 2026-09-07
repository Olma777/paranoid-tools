class Seedsplit < Formula
  desc "Split a secret into Shamir shares (pure Bash, GF(256))"
  homepage "https://github.com/Di-kairos/paranoid-tools"
  url "https://github.com/Di-kairos/paranoid-tools/archive/refs/tags/seedsplit-v0.5.8.tar.gz"
  sha256 "6cf7e2439143b13a74363ed63d13a5bd651a671d4ef40890fcffc0b9fc8ba1d0"
  license "MIT"

  def install
    bin.install "seedsplit/seedsplit"
  end

  test do
    assert_match "seedsplit", shell_output("#{bin}/seedsplit version")
  end
end
