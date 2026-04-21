#!/bin/bash
# build_android.sh
# Builds and signs the Android .aab for a specific tenant.
#
# Required env vars:
#   BUNDLE_ID_ANDROID, BUNDLE_ID_IOS, APP_NAME, API_BASE_URL, TENANT_ID
#
# Signing env vars (injected by platform per-build):
#   KEYSTORE_BASE64    Base64-encoded .jks keystore file
#   KEYSTORE_PASSWORD  Keystore + key password
#   KEYSTORE_ALIAS     Key alias inside the keystore
#
# Optional branding env vars:
#   LOGO_URL, SPLASH_BG_COLOR, SPLASH_BG_COLOR_DARK, ICON_BG_COLOR

set -e

# ─── Branding: icon + splash ────────────────────────────────────────────────
chmod +x scripts/configure_branding.sh
./scripts/configure_branding.sh

# ─── Android keystore setup ──────────────────────────────────────────────────
KEYSTORE_FILE="android/app/tenant-keystore.jks"

if [ -n "${KEYSTORE_BASE64:-}" ]; then
  echo "→ Decoding tenant keystore..."
  echo "$KEYSTORE_BASE64" | base64 --decode > "$KEYSTORE_FILE"
  echo "✅ Keystore written to $KEYSTORE_FILE"

  # Write key.properties for Gradle to pick up
  cat > android/key.properties <<EOF
storePassword=${KEYSTORE_PASSWORD}
keyPassword=${KEYSTORE_PASSWORD}
keyAlias=${KEYSTORE_ALIAS:-key}
storeFile=tenant-keystore.jks
EOF
  echo "✅ android/key.properties written"
else
  echo "⚠️  KEYSTORE_BASE64 not set — building unsigned (debug keystore will be used)"
fi

# ─── Build ──────────────────────────────────────────────────────────────────
flutter build appbundle \
  --dart-define=API_BASE_URL="${API_BASE_URL}" \
  --dart-define=TENANT_ID="${TENANT_ID}" \
  --dart-define=APP_NAME="${APP_NAME}" \
  --dart-define=BUNDLE_ID_ANDROID="${BUNDLE_ID_ANDROID}" \
  --dart-define=BUNDLE_ID_IOS="${BUNDLE_ID_IOS}" \
  --release

# ─── Cleanup: never leave keystore or key.properties on disk ────────────────
rm -f "$KEYSTORE_FILE" android/key.properties

echo "✅ Android .aab built: build/app/outputs/bundle/release/app-release.aab"
