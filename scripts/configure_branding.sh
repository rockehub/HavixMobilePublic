#!/bin/bash
# configure_branding.sh
# Downloads the tenant logo, generates app icon and native splash assets,
# then runs flutter_launcher_icons and flutter_native_splash:create.
#
# Must run AFTER `flutter pub get` and BEFORE `flutter build`.
# Failures in this step are non-fatal: the build continues with a placeholder icon.
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

# NOTE: no set -e — branding failures are non-fatal; build proceeds with placeholder

LOGO_URL="${LOGO_URL:-}"
API_BASE_URL="${API_BASE_URL:-}"
TENANT_ID="${TENANT_ID:-}"
SPLASH_BG="${SPLASH_BG_COLOR:-#ffffff}"
SPLASH_BG_DARK="${SPLASH_BG_COLOR_DARK:-#111827}"
ICON_BG="${ICON_BG_COLOR:-#ffffff}"

ICONS_DIR="assets/icons"
SPLASH_DIR="assets/splash"

mkdir -p "$ICONS_DIR" "$SPLASH_DIR"

# ─── Helper: skip branding gracefully ────────────────────────────────────────
skip_branding() {
  echo "⚠️  $1"
  echo "    Branding skipped — app will use placeholder icon and neutral splash."
  # Still generate splash/icons without a logo image so the build doesn't fail
  generate_splash_and_icons_without_logo
  exit 0
}

generate_splash_and_icons_without_logo() {
  echo "→ Generating splash (no logo — color-only)..."
  cat > flutter_native_splash.yaml <<EOF
flutter_native_splash:
  color: "$SPLASH_BG"
  color_dark: "$SPLASH_BG_DARK"

  android_12:
    color: "$SPLASH_BG"
    color_dark: "$SPLASH_BG_DARK"

  web: false
EOF
  dart run flutter_native_splash:create 2>/dev/null || true
}

# ─── 1. Resolve logo URL from storefront API if not explicitly provided ───────
if [ -z "$LOGO_URL" ] && [ -n "$API_BASE_URL" ] && [ -n "$TENANT_ID" ]; then
  echo "→ LOGO_URL not set — fetching from storefront resolve..."
  RESOLVE_JSON=$(curl -sf --max-time 10 \
    -H "X-Tenant-Id: $TENANT_ID" \
    "$API_BASE_URL/api/v1/storefront/resolve") || true

  if [ -n "$RESOLVE_JSON" ]; then
    LOGO_URL=$(python3 - <<'PY' "$RESOLVE_JSON"
import sys, json
data = json.loads(sys.argv[1])
logo = data.get('logo') or {}
print(logo.get('hdUrl') or logo.get('originalUrl') or logo.get('smUrl') or '')
PY
) || true
  fi
fi

# ─── 2. Validate logo URL ─────────────────────────────────────────────────────
if [ -z "$LOGO_URL" ]; then
  skip_branding "No LOGO_URL resolved (API_BASE_URL=${API_BASE_URL:-not set})."
fi

# Reject localhost/127.0.0.1 — not reachable from CI runner
if echo "$LOGO_URL" | grep -qE '(localhost|127\.0\.0\.1|0\.0\.0\.0)'; then
  skip_branding "LOGO_URL points to localhost ('$LOGO_URL') — not reachable from CI. Set APP_BASE_URL to the public API URL in your server config."
fi

# ─── 3. Download logo ─────────────────────────────────────────────────────────
echo "→ Downloading logo: $LOGO_URL"
if ! curl -fsSL --max-time 30 "$LOGO_URL" -o "$ICONS_DIR/raw_logo.png"; then
  skip_branding "Failed to download logo from '$LOGO_URL'."
fi

# Sanity-check: file must be at least 1 KB
LOGO_SIZE=$(wc -c < "$ICONS_DIR/raw_logo.png" 2>/dev/null || echo 0)
if [ "$LOGO_SIZE" -lt 1024 ]; then
  skip_branding "Downloaded logo is too small (${LOGO_SIZE} bytes) — likely not a valid image."
fi

echo "✅ Logo downloaded (${LOGO_SIZE} bytes)"

# ─── 4. Process with ImageMagick ──────────────────────────────────────────────
if command -v convert &>/dev/null; then
  echo "→ Processing icon assets with ImageMagick..."

  convert "$ICONS_DIR/raw_logo.png" \
    -background "$ICON_BG" -gravity center -resize 820x820 -extent 1024x1024 \
    "$ICONS_DIR/app_icon.png" 2>/dev/null || cp "$ICONS_DIR/raw_logo.png" "$ICONS_DIR/app_icon.png"

  convert "$ICONS_DIR/raw_logo.png" \
    -background none -gravity center -resize 640x640 -extent 1024x1024 \
    "$ICONS_DIR/app_icon_foreground.png" 2>/dev/null || cp "$ICONS_DIR/raw_logo.png" "$ICONS_DIR/app_icon_foreground.png"

  convert "$ICONS_DIR/raw_logo.png" \
    -background none -gravity center -resize 300x300 -extent 300x300 \
    "$SPLASH_DIR/splash_logo.png" 2>/dev/null || cp "$ICONS_DIR/raw_logo.png" "$SPLASH_DIR/splash_logo.png"

  echo "✅ Icon assets generated"
else
  echo "⚠️  ImageMagick not found — using raw logo without resizing"
  cp "$ICONS_DIR/raw_logo.png" "$ICONS_DIR/app_icon.png"
  cp "$ICONS_DIR/raw_logo.png" "$ICONS_DIR/app_icon_foreground.png"
  cp "$ICONS_DIR/raw_logo.png" "$SPLASH_DIR/splash_logo.png"
fi

# ─── 5. Write flutter_native_splash.yaml ─────────────────────────────────────
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

# ─── 6. Write flutter_launcher_icons.yaml ────────────────────────────────────
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

# ─── 7. Generate native splash + launcher icons ───────────────────────────────
dart run flutter_native_splash:create || echo "⚠️  flutter_native_splash:create failed — continuing"
dart run flutter_launcher_icons       || echo "⚠️  flutter_launcher_icons failed — continuing"

echo "✅ Branding configured"
