cask "revzen" do
  version "1.2.2"
  sha256 "e3345dc94fd2d0c5d9aaa0005f21146379ef9e5fef7f76bfd40504c7e24d5a8f"

  url "https://github.com/KilimcininKorOglu/Revzen/releases/download/v#{version}/Revzen.dmg",
      verified: "github.com/KilimcininKorOglu/Revzen/"
  name "Revzen"
  desc "Windows-style taskbar behavior for the macOS Dock"
  homepage "https://github.com/KilimcininKorOglu/Revzen"

  livecheck do
    url :url
    strategy :github_latest
  end

  # Revzen installs its own updates after checking the SHA-256 digest, the
  # minisign signature and the notarization ticket.
  auto_updates true
  depends_on macos: ">= :sequoia"

  app "Revzen.app"

  # Strip the quarantine xattr on install so Gatekeeper's CloudKit lookup
  # path is bypassed on first launch. The app is Developer ID signed,
  # hardened-runtime, and notarized with a stapled ticket.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Revzen.app"],
                   sudo: false
  end

  uninstall quit: "com.kilimcininkoroglu.revzen"

  zap trash: [
    "~/Library/Caches/Revzen",
    "~/Library/Preferences/com.kilimcininkoroglu.revzen.plist",
  ]
end
