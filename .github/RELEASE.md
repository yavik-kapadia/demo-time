# Release / CI-CD Setup

This project uses GitHub Actions to build, sign, notarize, and publish macOS releases.

## Triggers

- **Tag push:** Push a tag `v*` (e.g. `v1.0.0`) to create a release.
- **Manual:** Actions → Release → Run workflow (optionally set version).

## Required GitHub Secrets

Configure under **Settings → Secrets and variables → Actions**.

### For signing and notarization (recommended)

| Secret | Description |
|--------|-------------|
| `BUILD_CERTIFICATE_BASE64` | Your **Developer ID Application** certificate exported as `.p12`, then base64-encoded. `base64 -i YourCert.p12 \| pbcopy` |
| `P12_PASSWORD` | Password for the `.p12` file. |
| `KEYCHAIN_PASSWORD` | Any strong password; used for a temporary keychain in CI. |
| `APPLE_ID` | Apple ID email used for notarization. |
| `APPLE_APP_SPECIFIC_PASSWORD` | [App-specific password](https://support.apple.com/en-us/HT204397) for that Apple ID (not your normal password). |
| `APPLE_TEAM_ID` | Your Apple Developer Team ID (10 characters, e.g. `ADDSZMFEX9`). |
| `CODE_SIGN_IDENTITY` | (Optional) Full name of the signing identity, e.g. `Developer ID Application: Your Name (TEAM_ID)`. If unset, `Developer ID Application` is used. |

### Without secrets

The workflow still runs: it will build and create a release, but the app will use default runner signing and will **not** be notarized. Suitable for testing the pipeline; for public distribution you should add the secrets above.

## One-time Apple setup

1. **Developer ID Application certificate**  
   In [Apple Developer](https://developer.apple.com/account/resources/certificates/list): create a **Developer ID Application** certificate, download it, install in Keychain, then:
   - Export as `.p12` (File → Export in Keychain Access).
   - Base64-encode: `base64 -i YourCert.p12 | pbcopy` and paste into `BUILD_CERTIFICATE_BASE64`.

2. **App-specific password**  
   [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → App-Specific Passwords → Generate. Use this for `APPLE_APP_SPECIFIC_PASSWORD`.

3. **Team ID**  
   [developer.apple.com/account](https://developer.apple.com/account) → Membership details, or from your Apple Developer account in Xcode.

## Creating a release

**From a tag:**

```bash
git tag v1.0.0
git push origin v1.0.0
```

**Manual run:**

1. Open the repo on GitHub → **Actions** → **Release**.
2. Click **Run workflow**, optionally set **version** (e.g. `1.0.0`), then run.

The workflow produces a **Demo Time** release with `DemoTime-notarized.zip` (signed and notarized when secrets are set). Users can download the zip, unzip, and move **Demo Time.app** to Applications.
