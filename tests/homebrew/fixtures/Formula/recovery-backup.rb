class RecoveryBackup < Formula
  desc "Homebrew recovery test fixture"
  homepage "https://github.com/ppat/dotfiles"
  url "file://#{ENV.fetch('HOMEBREW_RECOVERY_TEST_ARCHIVE')}"
  version "1.0"
  sha256 ENV.fetch("HOMEBREW_RECOVERY_TEST_SHA256")
  link_overwrite "bin/dotfiles-recovery-test-tool"

  def install
    bin.install "dotfiles-recovery-test-tool"
  end

  post_install_steps do
    touch "postinstall-complete", base: :prefix
  end
end
