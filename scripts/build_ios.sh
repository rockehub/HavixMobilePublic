#!/bin/bash
# build_ios.sh
# Builds the iOS .ipa for a specific tenant.
# Must run on macOS with Xcode installed.
#
# Required env vars (same as build_android.sh + APPLE_TEAM_ID):
#   BUNDLE_ID_IOS, APP_NAME, API_BASE_URL, TENANT_ID, APPLE_TEAM_ID

set -e

# Step 1: branding (icon + splash)
chmod +x scripts/configure_branding.sh
./scripts/configure_branding.sh

# Step 2: generate TenantConfig.xcconfig
./scripts/configure_ios.sh

# Step 3: build ipa
flutter build ipa \
  --dart-define=API_BASE_URL="${API_BASE_URL}" \
  --dart-define=TENANT_ID="${TENANT_ID}" \
  --dart-define=APP_NAME="${APP_NAME}" \
  --dart-define=BUNDLE_ID_ANDROID="${BUNDLE_ID_ANDROID:-$BUNDLE_ID_IOS}" \
  --dart-define=BUNDLE_ID_IOS="${BUNDLE_ID_IOS}" \
  --release

echo "✅ iOS .ipa built: build/ios/ipa/*.ipa"
