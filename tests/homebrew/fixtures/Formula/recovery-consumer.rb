class RecoveryConsumer < Formula
  desc "Homebrew recovery test fixture"
  homepage "https://github.com/ppat/dotfiles"
  url "file://#{ENV.fetch('HOMEBREW_RECOVERY_TEST_ARCHIVE')}"
  version "1.0"
  sha256 ENV.fetch("HOMEBREW_RECOVERY_TEST_SHA256")
  depends_on "dotfiles-recovery-test/fixtures/recovery-backup"

  def install
    (prefix/"consumer-installed").write "complete\n"
  end
end
