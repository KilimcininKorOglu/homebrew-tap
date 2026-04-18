# homebrew-tap

Homebrew tap for [SplitWG](https://github.com/KilimcininKorOglu/SplitWG)
— a minimal macOS WireGuard tray app with per-config split tunneling.

## Install

```
brew tap KilimcininKorOglu/tap
brew install --cask splitwg
```

Or in a single command:

```
brew install --cask KilimcininKorOglu/tap/splitwg
```

## Upgrade

```
brew upgrade --cask splitwg
```

New releases are detected automatically via the cask's `livecheck` block
(GitHub Releases). The in-app updater continues to work alongside Homebrew;
if both mechanisms run, the later version wins.

## Uninstall

```
brew uninstall --cask splitwg
brew uninstall --zap --cask splitwg   # also removes ~/.config/splitwg
```

## Requirements

macOS 13 Ventura or newer. The app is Developer ID signed and notarized.

## Cask source

The canonical cask definition lives at `Casks/splitwg.rb` in this tap.
It is updated automatically by the main repository's release workflow on
every `v*` tag push (computes the universal DMG's SHA-256 and opens a
commit here).
