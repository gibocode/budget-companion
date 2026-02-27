## Publishing Budget Companion to Google Play

This guide assumes:

- You have a working Flutter environment.
- You can build and run the app locally.
- You have a Google Play Console account.

All commands below are meant to be run from the project root:

```bash
cd ~/flutter/budget_companion
```

---

### 1. Set the application ID (package name)

Pick a final application ID (cannot change after publishing), e.g.:

- `com.gibocode.budget_companion`

Then:

1. Open `android/app/build.gradle`.
2. In the `defaultConfig` block, set:

```gradle
applicationId "com.gibocode.budget_companion"
```

3. Make sure this ID matches what you create in Play Console.

---

### 2. Configure app name and icon

#### 2.1 App name (label)

In `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:label="Budget Companion"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher">
```

Change `android:label` only if you want a different store name. The Play Store listing title can be longer; this label is what appears under the app icon on the device.

#### 2.2 App icon

Use high‑resolution launcher icons that match Play policies:

1. Generate icons (e.g. with `flutter_launcher_icons`, Android Studio Image Asset Studio, or an online generator).
2. Replace the mipmap resources under `android/app/src/main/res/mipmap-*/ic_launcher.*`.
3. Keep `android:icon="@mipmap/ic_launcher"` in the manifest.

---

### 3. Set up signing for release

Google Play requires a **signed** release build. The recommended setup is:

1. **Create a keystore** (one time):

   ```bash
   cd android
   keytool -genkeypair -v \
     -keystore upload-keystore.jks \
     -storetype JKS \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias upload
   ```

   - Choose a **strong password** and remember it.
   - Fill in name/organization fields as you like.
   - This generates `android/upload-keystore.jks` (do **not** commit it to git).

2. **Create `key.properties`** in `android/`:

   ```properties
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```

   - Optional: keep an encrypted copy of this file; do not check it into public VCS.

3. **Wire signing into `android/app/build.gradle`** (if not already):

   ```gradle
   def keystoreProperties = new Properties()
   def keystorePropertiesFile = rootProject.file('key.properties')
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
   }

   android {
       ...
       signingConfigs {
           release {
               keyAlias keystoreProperties['keyAlias']
               keyPassword keystoreProperties['keyPassword']
               storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
               storePassword keystoreProperties['storePassword']
           }
       }

       buildTypes {
           release {
               signingConfig signingConfigs.release
               shrinkResources true
               minifyEnabled true
               proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
           }
       }
   }
   ```

---

### 4. Build the Play Store bundle (AAB)

Play now prefers an **Android App Bundle** (`.aab`):

```bash
cd ~/flutter/budget_companion
flutter clean
flutter pub get
flutter build appbundle --release
```

The output will be:

```text
build/app/outputs/bundle/release/app-release.aab
```

This is the file you will upload in Play Console.

You can also build an APK for local testing:

```bash
flutter build apk --release
```

The APK will be under `build/app/outputs/flutter-apk/app-release.apk`.

Install it on a device with:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

### 5. Create the app in Google Play Console

1. Go to **Google Play Console** and click **Create app**.
2. Enter:
   - App name: **Budget Companion**
   - Default language: e.g. **English (United States)**.
   - App or game: **App**
   - Free or paid: choose appropriately (likely **Free**).
3. Accept the declarations and continue.
4. When prompted for package name / application ID, use the value set in `applicationId` (e.g. `com.gibocode.budget_companion`).

---

### 6. Upload the release (internal testing first)

1. In Play Console, go to **Testing → Internal testing** (or **Closed testing**).
2. Create a new release.
3. Upload `app-release.aab`.
4. Fill in a short **release name** (e.g. `1.0.0 (1)`).
5. Add basic **release notes** (e.g. “Initial public release of Budget Companion.”).
6. Save and **roll out** to testers.

Once internal testing looks good, promote the same release track to **Production**.

---

### 7. Google Drive backup/restore (Google Sign-In)

The app’s **Google Drive backup and restore** use Google Sign-In and the Drive API. Sign-In only works when the app’s **signing certificate** is registered in Google Cloud.

**Local release APK: backup/restore not working**

- A **release** APK you build locally (`flutter build apk --release`) is signed with your **upload** keystore.
- If your OAuth client in Google Cloud only has the **debug** keystore’s SHA-1, Google Sign-In will fail for the release build, so backup and restore to Google Drive will not work.

**Fix: add your upload key SHA-1**

1. **Get the SHA-1 of your upload keystore:**
   ```bash
   keytool -list -v -keystore android/upload-keystore.jks -alias upload
   ```
   Enter the keystore password when prompted. Copy the **SHA1** (and **SHA-256**) from the output.

2. **Add it to your OAuth client:**
   - Open [Google Cloud Console](https://console.cloud.google.com/) → **APIs & Services** → **Credentials**.
   - Edit your **Android** OAuth 2.0 Client ID (package name `com.gibocode.budget_companion`).
   - Under **SHA-1 certificate fingerprints**, add the SHA-1 you copied (and SHA-256 if you want).
   - Save.

3. **Enable Google Drive API** in the same project: **APIs & Services** → **Library** → search “Google Drive API” → Enable.

After this, your **local release APK** can sign in and use backup/restore. No app code change needed.

**Published app (Play Store):** If you use Play App Signing, the app users install is signed with a different key. Add that **App signing key** SHA-1 from Play Console (Setup → App signing) to the same OAuth client so the published app can also use Google Drive backup/restore.

---

### 8. Store listing and policy requirements

Fill out these sections carefully; they are required for going live:

1. **Main store listing**
   - Short description (max 80 chars).
   - Full description (up to 4000 chars) – you can adapt content from `docs/USER_GUIDE.md`.
   - **App icon (512×512):** Use `store_listing/icon_512.png` from this repo (see `store_listing/README.md`).
   - **Feature graphic (1024×500):** Use `store_listing/feature_graphic_1024x500.png`.
   - **Screenshots:** Use the phone mockups in `store_listing/` (`screenshot_dashboard.png`, `screenshot_transactions.png`, `screenshot_budgets.png`) or capture real device screenshots; at least 2 per form factor (phone / tablet).
2. **Content rating** questionnaire.
3. **App category** – likely `Finance` → `Personal Finance`.
4. **Data safety** form:
   - Explain what data is stored locally and that backups are optional via Google Drive app data.
5. **Privacy policy**:
   - Host a simple privacy policy (e.g. on a small website or GitHub Pages) describing:
     - What data is stored (local device database, optional Drive backup).
     - That you don’t sell or share personal data.
   - Add the URL in Play Console under **App content → Privacy policy**.

---

### 9. Versioning for future updates

In `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

- The part before `+` is the **user-visible version** (`1.0.0`).
- The part after `+` is the **build number** (`1`, must be **monotonically increasing** for Play).

For each store update:

1. Bump the version, e.g. `1.0.1+2`.
2. Rebuild the bundle:

   ```bash
   flutter build appbundle --release
   ```

3. Upload the new `.aab` to Play Console as a new release.

---

### 10. Quick checklist before publishing

- [ ] App builds in **release** mode with no crashes on a real device.
- [ ] App name, icon, and package name are final.
- [ ] App lock, biometrics, and backup flows have been tested on device.
- [ ] **Google Drive backup/restore:** Release and Play App Signing SHA-1 are added to the OAuth client in Google Cloud (see §7).
- [ ] User-facing text and documentation are up to date (README, `docs/USER_GUIDE.md`).
- [ ] Privacy policy is published and linked in Play Console.
- [ ] Content rating and Data safety forms completed.
- [ ] At least one internal testing round completed.

