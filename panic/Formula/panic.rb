class Panic < Formula
  desc "One-step hide-and-lock kill-switch for macOS"
  homepage "https://github.com/Di-kairos/paranoid-tools"
  url "https://github.com/Di-kairos/paranoid-tools/archive/refs/tags/panic-v0.1.18.tar.gz"
  sha256 "3eed257fba5d8a1a27d7bc2646a57c395ff4920b53aa1d6516a3dec07eafc7f0"
  license "MIT"

  def install
    bin.install "panic/panic"
  end

  test do
    assert_match "panic", shell_output("#{bin}/panic version")
  end
end
