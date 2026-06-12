# RaastKar Deployment Guide
## Flutter Web + Android APK + iOS IPA + Render Backend

---

## What's In This Package

| File | Purpose |
|------|---------|
| `codemagic.yaml` | Builds Android APK/AAB, iOS IPA, and Flutter Web; auto-deploys web to GoDaddy |
| `render.yaml` | Deploys your Node.js backend to Render.com (Singapore region — closest to Pakistan) |
| `.github-workflows-deploy.yml` | Alternative GitHub Actions web deploy to GoDaddy (rename to `.github/workflows/deploy.yml`) |

---

## STEP 1 — GitHub Repo Setup

Your Flutter app needs to be in a GitHub repo. If it isn't yet:

```bash
cd /path/to/raastkar-flutter-app
git init
git add .
git commit -m "initial commit"
git remote add origin https://github.com/faridpremani/raastkar.git
git push -u origin main
```

Add a `.gitignore` — make sure these are ignored:
```
.dart_tool/
build/
android/.gradle/
android/local.properties
android/key.properties        # ← NEVER commit this — passwords inside
*.jks                         # ← NEVER commit keystore files
node_modules/
```

---

## STEP 2 — Codemagic Setup (Android + iOS + Web CI/CD)

1. Go to **https://codemagic.io** → Sign in with GitHub
2. **Add application** → select your `raastkar` repo
3. Codemagic will auto-detect `codemagic.yaml` ✓

### Android Signing (Environment Group)

In Codemagic → Teams → Global Variables → Create group: **`raastkar_android_signing`**

Add these variables:
| Variable | Value | Secret? |
|----------|-------|---------|
| `CM_KEYSTORE` | Base64-encoded `upload-keystore.jks` | ✅ Yes |
| `CM_KEYSTORE_PASSWORD` | `Raheem786!` | ✅ Yes |
| `CM_KEY_PASSWORD` | `Raheem786!` | ✅ Yes |
| `CM_KEY_ALIAS` | `upload` | No |

To base64-encode the keystore:
```bash
base64 -i android/upload-keystore.jks | pbcopy   # copies to clipboard on Mac
```

### iOS Signing

1. In Codemagic → go to **Code signing** tab
2. Upload your Apple Distribution certificate (.p12) and provisioning profile
3. Bundle ID: `com.raastkar.farming`
4. You need an **Apple Developer account** ($99/yr) — enroll at developer.apple.com

### FTP Credentials for Web Deploy (Group: `raastkar_ftp_credentials`)

| Variable | Value |
|----------|-------|
| `FTP_HOST` | Your GoDaddy FTP hostname (find in GoDaddy → Hosting → FTP) |
| `FTP_USER` | Your GoDaddy cPanel username |
| `FTP_PASS` | Your GoDaddy FTP password |

---

## STEP 3 — Flutter App → Point to Render Backend

In `lib/services/api_service.dart`, change the base URL from Vercel to Render:

```dart
// OLD (Vercel — your coworker's deployment):
static const String baseUrl = 'https://raastkar-backend.vercel.app';

// NEW (your Render deployment):
static const String baseUrl = 'https://raastkar-backend.onrender.com';
```

---

## STEP 4 — Render Backend Setup

> **Note:** The current app points to `raastkar-backend.vercel.app` — this is a Node.js/Next.js backend, not the Python FastAPI used for CartIQ. You need to get the backend source code from your coworker (contact@ignitethespark.org) and put it in a separate GitHub repo.

Once you have the backend repo:

1. Go to **https://render.com** → New → **Blueprint**
2. Connect your backend repo (e.g., `faridpremani/raastkar-backend`)
3. Render detects `render.yaml` and creates the service + database automatically
4. Set the secret env vars in the Render dashboard:
   - `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`
   - `STRIPE_SECRET_KEY` (your live Stripe key)
   - `OPENAI_API_KEY` (for AgriGPT)
   - `WEATHER_API_KEY`

Your backend URL will be: `https://raastkar-backend.onrender.com`

---

## STEP 5 — GoDaddy Web Deployment

The `web-release` workflow in `codemagic.yaml` handles this automatically on every push to `main`.

**Manual deploy** (if needed):
```bash
flutter build web --release --base-href="/" --web-renderer=canvaskit
# Then FTP the build/web/ folder to /public_html/raastkar.com/ in GoDaddy
```

---

## STEP 6 — Google Services (Firebase)

The app uses `google-services.json` (already in your Android folder). For iOS:
- Download `GoogleService-Info.plist` from Firebase Console
- Add it to `ios/Runner/` in your repo

---

## Build Triggers Summary

| Action | Result |
|--------|--------|
| Push to `main` branch | Auto-builds APK + AAB + Web in Codemagic |
| Merge PR to `main` | Same |
| Manual trigger in Codemagic | Build any workflow on demand |
| Web build success | Auto-FTPs to raastkar.com on GoDaddy |

---

## App Store / Play Store Submission

**Google Play:**
1. Create app at play.google.com/console
2. Upload the `.aab` file (not APK) for first submission
3. Once live, enable auto-publishing in `codemagic.yaml` (uncomment `google_play` section)

**Apple App Store:**
1. Create app at appstoreconnect.apple.com
2. Fill in `APP_STORE_APPLE_ID` in `codemagic.yaml`
3. Uncomment `app_store_connect` section for auto TestFlight uploads

---

## Important Security Notes

- **Never commit** `android/key.properties` or `*.jks` files to GitHub
- The keystore password (`Raheem786!`) is shared with CartIQ — consider using separate keystores per app
- Rotate Stripe keys if they were ever accidentally committed
