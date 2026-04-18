# Multi-App Tap Usage

This tap (`KilimcininKorOglu/homebrew-tap`) can host casks and formulas for **multiple applications**. One tap, one PAT, one unified `brew tap` command for all your apps.

## Layout

```
homebrew-tap/
├── Casks/
│   ├── splitwg.rb          # GUI app (.dmg)
│   ├── my-other-app.rb     # another GUI app
│   └── ...
├── Formula/                # optional, for CLI tools
│   └── my-cli.rb
└── README.md
```

- **Casks/** — GUI `.app` / `.dmg` distributions.
- **Formula/** — CLI binaries, libraries, source builds.

## Install commands

The install string follows the filename under `Casks/` or `Formula/`:

```
brew install --cask KilimcininKorOglu/tap/splitwg
brew install --cask KilimcininKorOglu/tap/my-other-app
brew install        KilimcininKorOglu/tap/my-cli
```

After a one-time `brew tap KilimcininKorOglu/tap`, users can drop the prefix:

```
brew tap KilimcininKorOglu/tap
brew install --cask splitwg my-other-app
brew install my-cli
```

## Adding a new application

1. In the app's own repository, add a release workflow (copy `SplitWG`'s `.github/workflows/release.yml` as a template).
2. The workflow's "Bump Homebrew cask" step clones this tap and edits **only its own cask file**:
   ```bash
   CASK="$WORK/tap/Casks/my-other-app.rb"
   /usr/bin/sed -i '' -E \
     -e "s/^  version \"[^\"]*\"/  version \"${VERSION}\"/" \
     -e "s/^  sha256 \"[0-9a-f]{64}\"/  sha256 \"${SHA256}\"/" \
     "$CASK"
   ```
3. Initial cask file: create manually and commit to this repo once (the workflow only bumps `version` + `sha256`, not the full file).
4. Reuse the same `HOMEBREW_TAP_TOKEN` PAT — its scope already covers this tap.

## Shared infrastructure

One PAT (`HOMEBREW_TAP_TOKEN`, `repo` scope on this tap only) is reused by every app's release workflow. Each app stores the same PAT as a secret in its own repository.

Livecheck (`livecheck :github_latest`) reads each app's own GitHub releases; casks do not interfere with one another.

## Conventions

- File names use kebab-case and match the `brew install` target: `Casks/foo-bar.rb` → `brew install --cask foo-bar`.
- Every cask must set `homepage`, `url` (pointing at its own repo's releases), `livecheck`, and appropriate `depends_on`.
- Each cask's `uninstall` / `zap` stanzas are app-specific.
- `README.md` at the tap root lists every published app (update it when a new cask is added).

## Minimal cask template

```ruby
cask "my-app" do
  version "1.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/KilimcininKorOglu/MyApp/releases/download/v#{version}/MyApp.dmg",
      verified: "github.com/KilimcininKorOglu/MyApp/"
  name "MyApp"
  desc "Short description of the app"
  homepage "https://github.com/KilimcininKorOglu/MyApp"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :ventura"

  app "MyApp.app"

  uninstall quit: "com.local.myapp"

  zap trash: [
    "~/.config/myapp",
    "~/Library/Preferences/com.local.myapp.plist",
  ]
end
```
