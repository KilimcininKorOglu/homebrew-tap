cask "splitwg" do
  version "1.0.1"
  sha256 "8e92513b3481ba2f8acc357f9d868753d29c36d83114e39cddfa3905431515da"

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
