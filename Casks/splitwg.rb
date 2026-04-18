cask "splitwg" do
  version "1.0.1"
  sha256 "bfd009b16033ed705b103856132d6ea45fd2a1358229dbfa40b96f8c62d7f91d"

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

  uninstall quit: "com.local.splitwg"

  zap trash: [
    "~/.config/splitwg",
    "~/Library/Caches/SplitWG",
    "~/Library/Preferences/com.local.splitwg.plist",
    "~/Library/Saved Application State/com.local.splitwg.savedState",
  ]
end
