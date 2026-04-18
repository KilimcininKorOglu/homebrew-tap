cask "splitwg" do
  version "1.0.1"
  sha256 "7060d3a266aa54f96b2c65e30be8b8eff029474811fa173f9de7a788c71272cb"

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
