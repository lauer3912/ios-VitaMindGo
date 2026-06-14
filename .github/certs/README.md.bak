# GitHub Actions Certificates & Keys

This directory stores certificates and API keys for CI/CD workflows.

## Required Files

### Code Signing Certificate (for TestFlight/App Store uploads)
- `.github/certs/szf_exported_cert.p12`
  - Export from macOS Keychain
  - Must include private key
  - Password stored in GitHub Secrets as `CERTIFICATE_PASSWORD`

### App Store Connect API Key (for automatic uploads)
- `.github/certs/AuthKey_{APPSTORE_API_KEY_ID}.p8`
  - Download from App Store Connect → Users & Access → Keys
  - The key ID must match `APPSTORE_API_KEY_ID` in GitHub Variables
  - Your Team ID must be set as `APPSTORE_TEAM_ID` in GitHub Variables

### Provisioning Profile (optional, auto-signing preferred)
- `.github/profiles/VitaMind_App_Store.mobileprovision`

## Security Note

**⚠️ Never commit certificate files to git!**

These files are in `.gitignore` but be careful:
1. Do NOT remove `.gitignore` entries for certs
2. Do NOT push certs to remote
3. Use GitHub Secrets for passwords
4. Use GitHub Variables for non-secret IDs

## Setup Instructions

1. Export your certificate from Keychain:
   ```bash
   security find-identity -v -p codesigning
   # Export the certificate as .p12 file
   ```

2. Create API Key in App Store Connect:
   - Go to App Store Connect → Users & Access → Keys
   - Create a new API Key with App Manager role
   - Download the .p8 file

3. Set GitHub Secrets:
   - `CERTIFICATE_PASSWORD`: Password for .p12 file
   - (API Key ID and Team ID go in Variables, not Secrets)

4. Set GitHub Variables:
   - `APPSTORE_API_KEY_ID`: Your API Key ID
   - `APPSTORE_TEAM_ID`: Your Team ID (9L6N2ZF26B)