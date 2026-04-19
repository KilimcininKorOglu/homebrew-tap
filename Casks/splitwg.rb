cask "splitwg" do
  version "1.0.3"
  sha256 "d54f8a685d0e03ae593d3d1793f1e70b932a40faf04e6cc8f74a82eca5438d91"

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

  uninstall quit: "com.kilimcininkoroglu.splitwg"

  zap trash: [
    "~/.config/splitwg",
    "~/Library/Caches/SplitWG",
    "~/Library/Preferences/com.kilimcininkoroglu.splitwg.plist",
    "~/Library/Saved Application State/com.kilimcininkoroglu.splitwg.savedState",
  ]
end
