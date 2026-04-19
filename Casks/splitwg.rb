cask "splitwg" do
  version "1.0.4"
  sha256 "ef406cbc6ae610924da060db5f8902f7aca83d7c7d04bde77095ce89cd3ad9f7"

  url "https://github.com/KilimcininKorOglu/SplitWG/releases/download/v#{version}/SplitWG.dmg",
      verified: "github.com/KilimcininKorOglu/SplitWG/"
  name "SplitWG"
  desc "Minimal macOS WireGuard tray app with per-config split tunneling"
  homepage "https://github.com/KilimcininKorOglu/SplitWG"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :ventura"

  app "SplitWG.app"

  # Strip the quarantine xattr on install so Gatekeeper's CloudKit
  # lookup path is bypassed on first launch. The app is Developer-ID
  # signed, hardened-runtime, and notarized with a stapled ticket
  # (verified offline via `codesign -dvvv` → "Notarization
  # Ticket=stapled"); without quarantine, macOS trusts the stapled
  # ticket and does not reach out to Apple's allow-list.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/SplitWG.app"],
                   sudo: false
  end

  uninstall quit: "com.kilimcininkoroglu.splitwg"

  zap trash: [
    "~/.config/splitwg",
    "~/Library/Caches/SplitWG",
    "~/Library/Preferences/com.kilimcininkoroglu.splitwg.plist",
    "~/Library/Saved Application State/com.kilimcininkoroglu.splitwg.savedState",
  ]
end
