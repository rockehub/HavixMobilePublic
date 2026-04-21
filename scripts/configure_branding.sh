#!/bin/bash
# configure_branding.sh
# Downloads the tenant logo, generates app icon and native splash assets,
# then runs flutter_launcher_icons and flutter_native_splash:create.
#
# Must run AFTER `flutter pub get` and BEFORE `flutter build`.
#
# Required env vars (at least one of):
#   LOGO_URL        Direct URL to the tenant logo (PNG/JPEG recommended, min 512x512)
#   API_BASE_URL    Used to fetch logo from storefront resolve if LOGO_URL is not set
#   TENANT_ID       Required when fetching from API
#
# Optional env vars:
#   SPLASH_BG_COLOR        Native splash background — light mode (default: #ffffff)
#   SPLASH_BG_COLOR_DARK   Native splash background — dark mode  (default: #111827)
#   ICON_BG_COLOR          Adaptive icon background color       (default: #ffffff)

set -e

LOGO_URL="${LOGO_URL:-}"
API_BASE_URL="${API_BASE_URL:-}"
TENANT_ID="${TENANT_ID:-}"
SPLASH_BG="${SPLASH_BG_COLOR:-#ffffff}"
SPLASH_BG_DARK="${SPLASH_BG_COLOR_DARK:-#111827}"
ICON_BG="${ICON_BG_COLOR:-#ffffff}"

ICONS_DIR="assets/icons"
SPLASH_DIR="assets/splash"

mkdir -p "$ICONS_DIR" "$SPLASH_DIR"

# ─── 1. Resolve logo URL from storefront API if not explicitly provided ───────
if [ -z "$LOGO_URL" ] && [ -n "$API_BASE_URL" ] && [ -n "$TENANT_ID" ]; then
  echo "→ LOGO_URL not set — fetching from storefront resolve..."
  RESOLVE_JSON=$(curl -sf \
    -H "X-Tenant-Id: $TENANT_ID" \
    "$API_BASE_URL/api/v1/storefront/resolve") || true

  if [ -n "$RESOLVE_JSON" ]; then
    LOGO_URL=$(python3 - <<'PY' "$RESOLVE_JSON"
import sys, json
data = json.loads(sys.argv[1])
logo = data.get('logo') or {}
print(logo.get('hdUrl') or logo.get('originalUrl') or logo.get('smUrl') or '')
PY
)
  fi
fi

# ─── 2. Download logo ─────────────────────────────────────────────────────────
if [ -z "$LOGO_URL" ]; then
  echo "⚠️  No LOGO_URL resolved — branding step skipped. App will use default placeholder icon."
  exit 0
fi

echo "→ Downloading logo: $LOGO_URL"
curl -fsSL "$LOGO_URL" -o "$ICONS_DIR/raw_logo.png"
echo "✅ Logo downloaded"

# ─── 3. Process with ImageMagick ──────────────────────────────────────────────
if command -v convert &>/dev/null; then
  echo "→ Processing icon assets with ImageMagick..."

  # App icon: 1024x1024, logo centered with white padding
  convert "$ICONS_DIR/raw_logo.png" \
    -background "$ICON_BG" \
    -gravity center \
    -resize 820x820 \
    -extent 1024x1024 \
    "$ICONS_DIR/app_icon.png"

  # Adaptive icon foreground: transparent background, logo centered
  convert "$ICONS_DIR/raw_logo.png" \
    -background none \
    -gravity center \
    -resize 640x640 \
    -extent 1024x1024 \
    "$ICONS_DIR/app_icon_foreground.png"

  # Native splash logo: 300x300 transparent, centered
  convert "$ICONS_DIR/raw_logo.png" \
    -background none \
    -gravity center \
    -resize 300x300 \
    -extent 300x300 \
    "$SPLASH_DIR/splash_logo.png"

  echo "✅ Icon assets generated with ImageMagick"
else
  echo "⚠️  ImageMagick (convert) not found — copying raw logo without processing"
  echo "    Install imagemagick in your CI image for best results."
  cp "$ICONS_DIR/raw_logo.png" "$ICONS_DIR/app_icon.png"
  cp "$ICONS_DIR/raw_logo.png" "$ICONS_DIR/app_icon_foreground.png"
  cp "$ICONS_DIR/raw_logo.png" "$SPLASH_DIR/splash_logo.png"
fi

# ─── 4. Rewrite flutter_native_splash.yaml with tenant colors + logo ──────────
echo "→ Writing flutter_native_splash.yaml..."
cat > flutter_native_splash.yaml <<EOF
flutter_native_splash:
  color: "$SPLASH_BG"
  color_dark: "$SPLASH_BG_DARK"
  image: assets/splash/splash_logo.png
  image_dark: assets/splash/splash_logo.png

  android_12:
    color: "$SPLASH_BG"
    color_dark: "$SPLASH_BG_DARK"
    image: assets/splash/splash_logo.png
    image_dark: assets/splash/splash_logo.png

  web: false
EOF
echo "✅ flutter_native_splash.yaml updated"

# ─── 5. Rewrite flutter_launcher_icons.yaml ───────────────────────────────────
echo "→ Writing flutter_launcher_icons.yaml..."
cat > flutter_launcher_icons.yaml <<EOF
flutter_launcher_icons:
  image_path: "assets/icons/app_icon.png"
  android: true
  ios: true
  remove_alpha_ios: true
  adaptive_icon_background: "$ICON_BG"
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"
  web:
    generate: false
EOF
echo "✅ flutter_launcher_icons.yaml updated"

# ─── 6. Generate native splash ────────────────────────────────────────────────
echo "→ Generating native splash..."
dart run flutter_native_splash:create
echo "✅ Native splash generated"

# ─── 7. Generate launcher icons ───────────────────────────────────────────────
echo "→ Generating launcher icons..."
dart run flutter_launcher_icons
echo "✅ Launcher icons generated"
