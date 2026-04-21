#!/bin/bash
# build_android.sh
# Builds the Android .aab for a specific tenant.
# The bundle ID and app name are injected via --dart-define into Gradle.
#
# Required env vars:
#   BUNDLE_ID_ANDROID   e.g. com.minha-loja.app
#   BUNDLE_ID_IOS       e.g. com.minha-loja.app
#   APP_NAME            e.g. Minha Loja
#   API_BASE_URL        e.g. https://api.havix.com
#   TENANT_ID           e.g. 82e25f39-b50a-4d9e-9ece-7ac8c7ff6bcc
#
# Optional env vars (branding):
#   LOGO_URL              Direct URL to tenant logo PNG (falls back to API resolve)
#   SPLASH_BG_COLOR       Light mode splash background (default: #ffffff)
#   SPLASH_BG_COLOR_DARK  Dark mode splash background  (default: #111827)
#   ICON_BG_COLOR         Adaptive icon background     (default: #ffffff)

set -e

# ─── Branding: icon + splash ────────────────────────────────────────────────
chmod +x scripts/configure_branding.sh
./scripts/configure_branding.sh

# ─── Build ──────────────────────────────────────────────────────────────────
flutter build appbundle \
  --dart-define=API_BASE_URL="${API_BASE_URL}" \
  --dart-define=TENANT_ID="${TENANT_ID}" \
  --dart-define=APP_NAME="${APP_NAME}" \
  --dart-define=BUNDLE_ID_ANDROID="${BUNDLE_ID_ANDROID}" \
  --dart-define=BUNDLE_ID_IOS="${BUNDLE_ID_IOS}" \
  --release

echo "✅ Android .aab built: build/app/outputs/bundle/release/app-release.aab"
