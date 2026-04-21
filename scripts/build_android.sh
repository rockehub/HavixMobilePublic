#!/bin/bash
# build_android.sh
# Builds and signs the Android .aab + .apk for a specific tenant.
#
# Required env vars:
#   BUNDLE_ID_ANDROID, BUNDLE_ID_IOS, APP_NAME, API_BASE_URL, TENANT_ID
#
# Signing env vars (injected by platform per-build):
#   KEYSTORE_BASE64       Base64-encoded .jks keystore file
#   KEYSTORE_PASSWORD_ENC AES-256-CBC-PBKDF2 encrypted keystore password
#   KEYSTORE_ALIAS        Key alias inside the keystore
#   KEYSTORE_ENCRYPTION_KEY  Decryption key (set in Codemagic as secure var)
#
# Optional branding env vars:
#   LOGO_URL, SPLASH_BG_COLOR, SPLASH_BG_COLOR_DARK, ICON_BG_COLOR

set -e

DART_DEFINES="--dart-define=API_BASE_URL=${API_BASE_URL} \
  --dart-define=TENANT_ID=${TENANT_ID} \
  --dart-define=APP_NAME=${APP_NAME} \
  --dart-define=BUNDLE_ID_ANDROID=${BUNDLE_ID_ANDROID} \
  --dart-define=BUNDLE_ID_IOS=${BUNDLE_ID_IOS}"

# ─── Branding: icon + splash ────────────────────────────────────────────────
chmod +x scripts/configure_branding.sh
./scripts/configure_branding.sh

# ─── Android keystore setup ──────────────────────────────────────────────────
KEYSTORE_FILE="android/app/tenant-keystore.jks"

if [ -n "${KEYSTORE_BASE64:-}" ]; then
  echo "→ Decoding tenant keystore..."
  echo "$KEYSTORE_BASE64" | base64 --decode > "$KEYSTORE_FILE"
  echo "✅ Keystore written to $KEYSTORE_FILE"

  if [ -n "${KEYSTORE_ENCRYPTION_KEY:-}" ]; then
    KEYSTORE_PASSWORD=$(echo "${KEYSTORE_PASSWORD_ENC}" | \
      openssl enc -aes-256-cbc -pbkdf2 -iter 10000 -a -d \
      -pass pass:"${KEYSTORE_ENCRYPTION_KEY}" 2>/dev/null)
    if [ -z "$KEYSTORE_PASSWORD" ]; then
      echo "❌ Failed to decrypt KEYSTORE_PASSWORD_ENC — check that KEYSTORE_ENCRYPTION_KEY matches the backend."
      exit 1
    fi
    echo "✅ Keystore password decrypted"
  else
    KEYSTORE_PASSWORD="${KEYSTORE_PASSWORD_ENC:-}"
    echo "⚠️  KEYSTORE_ENCRYPTION_KEY not set — using password as plain text (dev mode only)"
  fi

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

# ─── Build .aab (Play Store) ─────────────────────────────────────────────────
echo "→ Building .aab..."
flutter build appbundle $DART_DEFINES --release
echo "✅ .aab built: build/app/outputs/bundle/release/app-release.aab"

# ─── Build .apk (sideload / distribuição direta) ─────────────────────────────
echo "→ Building .apk..."
flutter build apk $DART_DEFINES --release
echo "✅ .apk built: build/app/outputs/flutter-apk/app-release.apk"

# ─── Cleanup: never leave keystore or key.properties on disk ─────────────────
rm -f "$KEYSTORE_FILE" android/key.properties
