class Vaultwatch < Formula
  desc "Guard an open securetrash vault on macOS (Spotlight/Time Machine/cloud)"
  homepage "https://github.com/Di-kairos/paranoid-tools"
  url "https://github.com/Di-kairos/paranoid-tools/archive/refs/tags/vaultwatch-v0.1.17.tar.gz"
  sha256 "9c5e1b0dad5d67b52242186f2080876dedb1f501ed88c756fe4d6f2baed355b5"
  license "MIT"

  def install
    bin.install "vaultwatch/vaultwatch"
  end

  test do
    assert_match "vaultwatch", shell_output("#{bin}/vaultwatch version")
  end
end
