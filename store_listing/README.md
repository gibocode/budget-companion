# Google Play Store Listing Assets

This folder contains sample assets for the **Budget Companion** store listing.

## Contents

| File | Purpose | Google Play requirement |
|------|--------|-------------------------|
| `icon_512.png` | **App icon** for store listing | 512 × 512 px, 32-bit PNG (with alpha) |
| `feature_graphic_1024x500.png` | **Feature graphic** (banner at top of listing) | 1024 × 500 px, JPEG or 24-bit PNG |
| `screenshot_dashboard.png` | Phone screenshot – Dashboard | Min 320px on shortest side, max 3840px |
| `screenshot_transactions.png` | Phone screenshot – Transactions | Same as above |
| `screenshot_budgets.png` | Phone screenshot – Budgets | Same as above |

Screenshots use **mock data** for display only. You can replace them with real device screenshots (with test data) if you prefer.

## Uploading in Play Console

1. **Main store listing**
   - **App icon:** Upload `icon_512.png` (512 × 512).
   - **Feature graphic:** Upload `feature_graphic_1024x500.png` (1024 × 500).
   - **Phone screenshots:** Upload at least 2 of the screenshot images (e.g. dashboard + transactions + budgets). You can add more later.

2. If the generated images are not exactly the required pixel dimensions, resize them with an image editor or tool (e.g. ImageMagick, Figma, or Google Play’s own resize hints) before uploading.

3. All assets must meet [Google Play’s asset guidelines](https://support.google.com/googleplay/android-developer/answer/9866151).
