cask "revzen" do
  version "1.3.5"
  sha256 "13b5df73e4225749203c3bd4e23cae72f0abcb642a8209d8b1e704d000bd8662"

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
