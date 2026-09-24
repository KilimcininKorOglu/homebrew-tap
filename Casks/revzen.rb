cask "revzen" do
  version "1.1.0"
  sha256 "86742863cc868d4695a4236e6b9047af0e51196490e3c7680aa66bdb9728f342"

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
