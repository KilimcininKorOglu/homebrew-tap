# macOS App Release, Signing & Auto-Update Reference

End-to-end reference for shipping a macOS GUI or CLI app with Developer ID codesigning, Apple notarization, minisign detached signatures, in-app auto-update, and Homebrew cask distribution. Distilled from the SplitWG pipeline.

## Architecture overview

```
tag push (v*)
    │
    ▼
.github/workflows/release.yml (macos-14 runner)
    │
    ├── Import Developer ID cert into a keychain
    ├── Configure notarytool credentials
    ├── Install minisign private key
    ├── make release
    │       ├── cargo build --release (universal / intel / arm)
    │       ├── create .app bundles
    │       ├── codesign (hardened runtime + timestamp + entitlements)
    │       ├── create .dmg via create-dmg
    │       ├── notarize + staple (xcrun notarytool)
    │       └── minisign -S (detached .minisig siblings)
    ├── Verify (spctl + minisign -V)
    ├── Publish GitHub Release (6 assets: 3 DMGs + 3 .minisig)
    └── Bump Homebrew cask in tap repo
            └── sed rewrites version + sha256; commit; push
                    │
                    ▼
            Users run brew upgrade / in-app updater
                    │
                    ▼
            App verifies: minisign + SHA-256 + spctl/codesign Team ID
```

Three independent signature layers protect every release:

| Layer         | Produced by             | Verified by (client)                      |
|---------------|-------------------------|-------------------------------------------|
| Developer ID  | `codesign` + `notarytool` | `spctl -a -vv -t exec` / install          |
| Apple notary  | Ticket stapled into DMG | `spctl` says "source=Notarized Developer ID" |
| Minisign      | `minisign -S`           | `minisign -V -p <baked pubkey>`            |

## One-time setup

### Apple Developer

1. Join the Apple Developer Program (Individual or Organization). Note the 10-character **Team ID** (e.g. `ABC1234567`).
2. In Keychain Access: **Certificate Assistant → Request a Certificate From a Certificate Authority** → Common Name = your legal name, Request = Saved to disk. Save `.certSigningRequest`.
3. [developer.apple.com/account](https://developer.apple.com/account) → Certificates → **+** → **Developer ID Application** → G2 Sub-CA → upload the CSR → download `.cer` → double-click to install.
4. Create an app-specific password at [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → App-Specific Passwords.
5. Export the certificate + private key from Keychain Access as `.p12` (select the Developer ID Application certificate, right-click → Export 2 items). Set a strong password.

Verify:
```bash
security find-identity -v -p codesigning | grep "Developer ID Application"
```

### Minisign

```bash
# Generate key pair (do this once per project; store private key OUTSIDE git).
minisign -G -p resources/app.pub -s ~/.minisign/app.key
```

The `.pub` file ships in the binary via `include_str!` / equivalent. The `.key` is a GitHub secret.

### GitHub PAT for Homebrew tap

[github.com/settings/tokens](https://github.com/settings/tokens) → Fine-grained token → repository access limited to your tap only → `Contents: Read and write`.

### GitHub repository secrets

| Secret                          | Value                                                  |
|---------------------------------|--------------------------------------------------------|
| `APPLE_DEVELOPER_ID_CERT_P12`   | `base64 -i cert.p12`                                   |
| `APPLE_DEVELOPER_ID_CERT_PWD`   | `.p12` password                                        |
| `APPLE_ID`                      | Apple Developer account email                          |
| `APPLE_TEAM_ID`                 | 10-character Team ID                                   |
| `APPLE_APP_SPECIFIC_PWD`        | App-specific password                                  |
| `MINISIGN_KEY`                  | `base64 -i ~/.minisign/app.key`                        |
| `MINISIGN_KEY_PWD`              | Minisign private key passphrase                        |
| `HOMEBREW_TAP_TOKEN`            | GitHub PAT scoped to the tap repo                      |

## release.yml (GitHub Actions)

```yaml
name: Release

on:
  push:
    tags: ['v*']
  workflow_dispatch:

permissions:
  contents: write          # REQUIRED for softprops/action-gh-release

jobs:
  release:
    runs-on: macos-14
    timeout-minutes: 90
    steps:
      - uses: actions/checkout@v4

      - name: Install Rust toolchain
        run: rustup toolchain install stable --profile minimal

      - name: Cache cargo
        uses: actions/cache@v4
        with:
          path: |
            ~/.cargo/registry
            ~/.cargo/git
            target
          key: ${{ runner.os }}-cargo-release-${{ hashFiles('Cargo.lock') }}

      - name: Install minisign + create-dmg
        run: brew install minisign create-dmg

      - name: Import Developer ID certificate
        env:
          CERT_P12_B64: ${{ secrets.APPLE_DEVELOPER_ID_CERT_P12 }}
          CERT_PWD:     ${{ secrets.APPLE_DEVELOPER_ID_CERT_PWD }}
        run: |
          set -euo pipefail
          echo "$CERT_P12_B64" | base64 -d > /tmp/cert.p12
          KEYCHAIN=build.keychain
          security create-keychain -p actions "$KEYCHAIN"
          security default-keychain -s "$KEYCHAIN"
          security unlock-keychain -p actions "$KEYCHAIN"
          security set-keychain-settings -lut 21600 "$KEYCHAIN"
          security import /tmp/cert.p12 -k "$KEYCHAIN" -P "$CERT_PWD" \
            -T /usr/bin/codesign -T /usr/bin/security
          security set-key-partition-list -S apple-tool:,apple: \
            -s -k actions "$KEYCHAIN"

      - name: Configure notarytool profile
        env:
          APPLE_ID:      ${{ secrets.APPLE_ID }}
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
          APPLE_APP_PWD: ${{ secrets.APPLE_APP_SPECIFIC_PWD }}
        run: |
          xcrun notarytool store-credentials app-notary \
            --apple-id   "$APPLE_ID" \
            --team-id    "$APPLE_TEAM_ID" \
            --password   "$APPLE_APP_PWD"

      - name: Install minisign private key
        env:
          MINISIGN_KEY_B64: ${{ secrets.MINISIGN_KEY }}
        run: |
          mkdir -p ~/.minisign
          echo "$MINISIGN_KEY_B64" | base64 -d > ~/.minisign/app.key
          chmod 600 ~/.minisign/app.key

      - name: Build, sign, notarize, minisign
        env:
          MINISIGN_PASSWORD: ${{ secrets.MINISIGN_KEY_PWD }}
        run: make release

      - name: Verify artifacts
        run: |
          set -euo pipefail
          for dmg in dist/*.dmg; do
            spctl -a -vv -t install "$dmg" || true
            minisign -V -p resources/app.pub -m "$dmg"
          done

      - name: Publish GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: |
            dist/*.dmg
            dist/*.dmg.minisig
          generate_release_notes: true

      - name: Bump Homebrew cask
        if: startsWith(github.ref, 'refs/tags/v')
        env:
          HOMEBREW_TAP_TOKEN: ${{ secrets.HOMEBREW_TAP_TOKEN }}
        run: |
          set -euo pipefail
          [ -z "${HOMEBREW_TAP_TOKEN:-}" ] && exit 0
          VERSION="${GITHUB_REF_NAME#v}"
          SHA256=$(shasum -a 256 dist/App.dmg | awk '{print $1}')
          WORK=$(mktemp -d)
          git clone --depth 1 \
            "https://x-access-token:${HOMEBREW_TAP_TOKEN}@github.com/<user>/homebrew-tap.git" \
            "$WORK/tap"
          CASK="$WORK/tap/Casks/app.rb"
          /usr/bin/sed -i '' -E \
            -e "s/^  version \"[^\"]*\"/  version \"${VERSION}\"/" \
            -e "s/^  sha256 \"[0-9a-f]{64}\"/  sha256 \"${SHA256}\"/" \
            "$CASK"
          cd "$WORK/tap"
          git config user.name  "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git diff --quiet || {
            git add "$CASK"
            git commit -m "app ${VERSION}"
            git push origin main
          }
```

## Makefile targets

Key rules shown. Full Makefile at [SplitWG's Makefile](https://github.com/KilimcininKorOglu/SplitWG/blob/main/Makefile).

```makefile
release: dmg dmg-intel dmg-arm notarize sign-minisign

# Codesign uses an entitlements plist that includes
# com.apple.security.cs.disable-library-validation for cross-arch dylibs.
codesign-app:
	codesign --force --options runtime --timestamp \
	         --entitlements app.entitlements \
	         --sign "$(DEV_ID)" $(APP)

# Notarize + staple each DMG.
notarize:
	xcrun notarytool submit dist/App.dmg \
	      --keychain-profile app-notary --wait
	xcrun stapler staple dist/App.dmg

# Minisign detached signatures. Pipe the passphrase via stdin in CI;
# minisign does NOT read the MINISIGN_PASSWORD env var directly.
sign-minisign:
	@for img in $(DMG) $(DMG_INTEL) $(DMG_ARM); do \
	    if [ -f "$$img" ]; then \
	        if [ -n "$${MINISIGN_PASSWORD:-}" ]; then \
	            printf '%s\n' "$$MINISIGN_PASSWORD" | \
	                minisign -S -s $(MINISIGN_KEY) -m "$$img"; \
	        else \
	            minisign -S -s $(MINISIGN_KEY) -m "$$img"; \
	        fi; \
	    fi; \
	done
```

### Entitlements plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
</dict>
</plist>
```

`disable-library-validation` is required when loading dynamic libraries not signed by the same Team ID (e.g. Homebrew Tcl/Tk, FFmpeg). Without it the app crashes at load time under hardened runtime.

## In-app auto-update (triple verification)

Chain (pseudocode):

```
1. Check latest release via GitHub API
2. Download <asset>.dmg and <asset>.dmg.minisig
3. Verify streaming SHA-256 digest matches asset.digest (GitHub API)
4. Verify minisign signature against baked-in pubkey:
     let pk = PublicKey::decode(include_str!("../resources/app.pub").trim())?;
     let sig = Signature::decode(sig_content.trim())?;
     pk.verify(data_bytes, &sig, false)?;
5. Mount the DMG with:
     hdiutil attach -nobrowse -quiet -noautoopen <dmg>
6. Extract Team ID from the bundled app:
     codesign -dv --verbose=4 <App.app>
     # stderr contains "TeamIdentifier=ABC1234567"
7. Reject unless matches the running app's Team ID.
8. Verify notarization:
     spctl -a -vv -t exec <App.app>
     # must print "source=Notarized Developer ID" and "accepted"
9. Replace app:
     - /Applications/*  → prompt for admin (osascript with administrator privileges)
     - elsewhere        → direct replace
10. Relaunch: open -n <new app>; exit(0)
```

Cooldown: 24 h for background update polling. Users can force a check. Artifact cleanup cooldown is separate (7 days).

### Key rotation policy

The minisign public key is compiled into the binary. Rotating the private key requires cutting a new release with the new public key **first**; older installs only trust the baked-in value and must install the new build manually before auto-update resumes.

## Homebrew cask

See `MULTI-APP.md` for hosting multiple apps in one tap. Minimal cask:

```ruby
cask "app" do
  version "1.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/<user>/<repo>/releases/download/v#{version}/App.dmg",
      verified: "github.com/<user>/<repo>/"
  name "App"
  desc "Short description"
  homepage "https://github.com/<user>/<repo>"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :ventura"

  app "App.app"

  uninstall quit: "com.example.app"

  zap trash: [
    "~/.config/app",
    "~/Library/Preferences/com.example.app.plist",
  ]
end
```

## Troubleshooting

| Symptom                                                      | Cause                                                             | Fix                                                               |
|--------------------------------------------------------------|-------------------------------------------------------------------|-------------------------------------------------------------------|
| `make: *** [sign-minisign] Error 2`, `Password: get_password()` | Makefile passes `minisign -S` without piping passphrase          | `printf '%s\n' "$MINISIGN_PASSWORD" \| minisign -S -s KEY -m FILE` |
| Publish step: `403 Resource not accessible by integration`    | Workflow lacks `contents: write`                                 | Add `permissions: { contents: write }` at workflow or job level   |
| `spctl` says "source=Unnotarized Developer ID"               | Notarization not stapled or rejected                              | Check `xcrun notarytool log <id> --keychain-profile ...`          |
| `codesign` fails: "resource fork, Finder info, or similar"   | Extended attributes on source files                               | `xattr -rc /path/to/SourceTree`                                   |
| Notarization rejected: missing hardened runtime              | `codesign` without `--options runtime`                            | Add `--options runtime` to every codesign call                    |
| Notarization rejected: invalid entitlements                  | Sandbox + library-validation mismatch                             | Revisit entitlements plist; drop sandbox for Developer ID apps    |
| DMG upload: `EPIPE` / `ENOTCONN`                             | Apple notary transient network error                              | Retry; add `--wait-retries 3` if supported                        |
| Release created but no cask bump                             | `HOMEBREW_TAP_TOKEN` unset or scoped wrong                        | Fine-grained PAT needs `Contents: Read and write` on tap only     |
| Key rotation breaks older installs                           | Public key is baked in; old binaries reject new signatures        | Ship a migration build with BOTH keys accepted, then rotate       |

## Checklist for a new app

1. Pick a bundle id (`com.example.appname`) and register at Apple Developer portal.
2. Generate minisign key pair; bake `.pub` into the binary.
3. Write `release.yml` from the template above (substitute repo / cask names).
4. Add entitlements plist (`network.client` + `cs.disable-library-validation` if needed).
5. Add the 8 GitHub secrets listed in "One-time setup".
6. Create the initial cask in the tap repo (`Casks/<app>.rb`, correct filename for `brew install --cask <app>`).
7. Tag `v0.1.0`, push, watch Actions.
8. Verify: `brew tap <user>/tap && brew install --cask <app>`; launch app; check for updates.
9. Document the in-app update verification chain in user-facing docs.
10. For every subsequent release: one command (`/version-update patch` or manual tag + push).
