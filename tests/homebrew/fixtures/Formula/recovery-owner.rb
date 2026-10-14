class RecoveryOwner < Formula
  desc "Homebrew recovery test fixture"
  homepage "https://github.com/ppat/dotfiles"
  url "file://#{ENV.fetch('HOMEBREW_RECOVERY_TEST_ARCHIVE')}"
  version "1.0"
  sha256 ENV.fetch("HOMEBREW_RECOVERY_TEST_SHA256")

  def install
    bin.install "dotfiles-recovery-test-tool"
  end
end
