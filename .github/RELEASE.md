# Release setup – step-by-step guide

This project uses GitHub Actions to build, sign, notarize, and publish macOS releases. If you skip secrets, the workflow still runs but the app will not be properly signed or notarized. Follow the steps below in order to get a fully signed and notarized release.

---

## Part A – Prerequisites and GitHub

**Step 1.** Ensure you have an **Apple Developer Program** membership ($99/year). You need it for the certificate and notarization.

**Step 2.** Open your repo on GitHub → **Settings** → **Secrets and variables** → **Actions**. You will add secrets here as you obtain them in the steps below.

---

## Part B – Apple account (order matters)

**Step 3. Get your Team ID**

- Go to [developer.apple.com/account](https://developer.apple.com/account) and sign in.
- Click **Membership details** (or **Account** → Membership).
- Copy your **Team ID** (10 characters, e.g. `ADDSZMFEX9`).
- In GitHub: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**. Name: `APPLE_TEAM_ID`. Value: paste the Team ID. Save.

**Step 4. Set your Apple ID**

- Use the Apple ID email you use for the Developer Program.
- In GitHub: New secret. Name: `APPLE_ID`. Value: that email. Save.

**Step 5. Create an app-specific password**

- Go to [appleid.apple.com](https://appleid.apple.com) → sign in → **Sign-In and Security** → **App-Specific Passwords**.
- Click **Generate** (or **+**). Name it e.g. “GitHub Actions Demo Time”.
- Apple shows a password like `xxxx-xxxx-xxxx-xxxx`. Copy it **once** (it is not shown again).
- In GitHub: New secret. Name: `APPLE_APP_SPECIFIC_PASSWORD`. Value: paste the full string including hyphens. Save.

---

## Part C – Developer ID certificate and .p12

**Step 6. Create a Developer ID Application certificate**

- Go to [Apple Developer → Certificates, Identifiers & Profiles → Certificates](https://developer.apple.com/account/resources/certificates/list).
- Click **+** to add a certificate.
- Choose **Developer ID Application** → **Continue**.

**Step 7. Create a Certificate Signing Request (CSR) on your Mac**

- On your Mac, open **Keychain Access** (Applications → Utilities).
- Menu: **Keychain Access** → **Certificate Assistant** → **Request a Certificate From a Certificate Authority**.
- Enter your email, common name (e.g. your name), leave “CA Email” blank. Choose **Saved to disk**.
- Save the `.certSigningRequest` file.
- Back in the browser (Apple Developer), upload that `.certSigningRequest` file.
- Click **Continue**, then **Download** to get the `.cer` file.

**Step 8. Install the certificate**

- Double-click the downloaded `.cer` file. It installs into your **login** keychain.

**Step 9. Export the certificate as a .p12 file**

- Open **Keychain Access**. In the left sidebar, select **login** (or **System**). In the category list below, click **My Certificates** so only certificates are shown.
- Find **Developer ID Application: Your Name**. Click the **disclosure triangle** next to it so it expands—you should see the certificate and a **Private Key** listed under it. The .p12 must include the private key.
- Select the **parent row** (the one that says “Developer ID Application: Your Name”), not only the key. That way both the certificate and its private key are selected.
- Menu: **File** → **Export "Developer ID Application: …"** (or **Export Items…**). If **Export** is grayed out, you may have selected only the key or only the cert—click the parent row again so the whole identity is selected, then try **File** → **Export** again.
- Save as e.g. `demotime.p12`. Choose a **strong password** and remember it (this will be `P12_PASSWORD`). Save.

**If Export is still grayed out or doesn’t work**

- You must export on the **same Mac** that created the Certificate Signing Request (CSR). The private key exists only on that machine. If you created the CSR on another Mac, use that Mac to export the .p12 (or create a new Developer ID certificate and CSR on this Mac and use that).
- Try switching the keychain: in the left sidebar, select **login**, then in the list find the certificate again and try exporting. If the cert is under **System**, you may need to drag it into **login** (drag “Developer ID Application: Your Name” from System to login), then export from login.
- Quit Keychain Access, reopen it, then repeat: expand the certificate, select the parent row, **File** → **Export**.

**Step 10. Add the .p12 and keychain secrets to GitHub**

- In **Terminal**, go to the folder where you saved the `.p12` file (e.g. `cd ~/Desktop`).
- Run: `base64 -i demotime.p12 | pbcopy` (replace `demotime.p12` with your filename). This copies the base64-encoded certificate to the clipboard.
- In GitHub: New secret. Name: `BUILD_CERTIFICATE_BASE64`. Value: paste from clipboard (one long line). Save.
- New secret. Name: `P12_PASSWORD`. Value: the password you set when exporting the `.p12`. Save.
- Generate a random password for the temporary CI keychain: run `openssl rand -base64 24` in Terminal. New secret. Name: `KEYCHAIN_PASSWORD`. Value: that output. Save.

**Step 11. Get the exact signing identity and add CODE_SIGN_IDENTITY**

- In Terminal, run: `security find-identity -v -p codesigning`
- Find the line that shows **Developer ID Application: Your Name (TEAM_ID)**. Example: `Developer ID Application: Yavik Kapadia (ADDSZMFEX9)`.
- Copy the **entire** string (including “Developer ID Application:”, your name, and the parentheses with Team ID). Do not add extra quotes or spaces.
- In GitHub: New secret. Name: `CODE_SIGN_IDENTITY`. Value: that exact string. Save.
- Confirm that the Team ID in this string matches the value you set for `APPLE_TEAM_ID` in Step 3.

---

## Part D – Run and verify

**Step 12. Trigger a release**

- **Option A (manual):** On GitHub → **Actions** → **Release** → **Run workflow**. Optionally set the version (e.g. `1.0.0`) → **Run workflow**.
- **Option B (tag):** In Terminal, from your repo: `git tag v1.0.0` then `git push origin v1.0.0`.

The workflow will build the app, sign it with your certificate, notarize it, and create a release with `DemoTime-notarized.zip`. Users can download the zip, unzip it, and move **Demo Time.app** to Applications.

**Step 13. If the build fails with “No certificate for team matching…”**

- Double-check that `CODE_SIGN_IDENTITY` is the **full** string from Step 11 (e.g. `Developer ID Application: Your Name (ADDSZMFEX9)`).
- Confirm `APPLE_TEAM_ID` matches the Team ID inside that string.
- Ensure there are no leading or trailing spaces in the secret values.
- **Alternative:** Set `CODE_SIGN_IDENTITY` to the identity’s **SHA-1 hash** (e.g. `69F41B06E1F350EAFB8CB3CFB892B724A3EDB3C8`). Run `security find-identity -v -p codesigning` locally and use the hash from the "Developer ID Application" line.
- Re-run the workflow.

---

## Part E – Quick reference

| Secret | What it is |
|--------|------------|
| `APPLE_TEAM_ID` | Your 10-character Apple Developer Team ID. |
| `APPLE_ID` | Apple ID email for the Developer Program. |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password from appleid.apple.com. |
| `BUILD_CERTIFICATE_BASE64` | Your Developer ID Application certificate as .p12, base64-encoded. |
| `P12_PASSWORD` | Password you set when exporting the .p12. |
| `KEYCHAIN_PASSWORD` | Random string used for the temporary CI keychain (e.g. `openssl rand -base64 24`). |
| `CODE_SIGN_IDENTITY` | Exact identity string from `security find-identity -v -p codesigning` (e.g. `Developer ID Application: Your Name (TEAM_ID)`). |

**Creating a release:** Run the **Release** workflow manually from Actions, or push a tag `v*` (e.g. `v1.0.0`).
