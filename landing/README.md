# Budget Companion — Landing Page

One-page responsive website for the Budget Companion Android app. Users can read about the app and download the APK directly.

## What’s included

- **index.html** — Single-page layout: hero, features, screenshots, download CTA.
- **styles.css** — Responsive styles using the app’s green (#00AF54) and modern typography (DM Sans).
- **Assets** — Uses images from the project’s `store_listing/` folder (icon, feature graphic, screenshots).

## APK download

The “Download APK” button points to **`app-release.apk`** in this folder.

**To enable downloads:**

1. Build the release APK:
   ```bash
   cd ..   # project root
   flutter build apk --release
   ```
2. Copy the APK into this folder and name it `app-release.apk`:
   ```bash
   cp build/app/outputs/flutter-apk/app-release.apk landing/app-release.apk
   ```

Alternatively, change the download link in `index.html` to point to your own URL (e.g. a Play Store link or a file host).

## Serving the page

From the **project root** (so that `store_listing/` and `landing/` are both available):

```bash
# Python 3
python3 -m http.server 8080

# Then open: http://localhost:8080/landing/
```

Or open `landing/index.html` directly in a browser; assets will load if the folder structure is intact (project root contains both `landing/` and `store_listing/`).

## Deployment

Upload the contents of `landing/` to your web host. Ensure:

- `store_listing/` assets are reachable at the same relative path (e.g. `../store_listing/` from `landing/index.html`), **or**
- Copy the needed images into `landing/` and update paths in `index.html` (e.g. `images/icon_512.png`).

Add `app-release.apk` to the same folder as `index.html` (or update the download link).
