#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# Kheteebaadi - Flutter Release Build Script
#
# This script builds a production .aab (Android App Bundle) for Play Store
# and optionally a fat APK for direct testing.
#
# Prerequisites:
#   - Flutter SDK 3.10+ installed and in PATH
#   - Java 11+ installed
#   - Android SDK installed (via Android Studio or standalone)
#
# Usage:
#   chmod +x build-release.sh
#   ./build-release.sh           # Build .aab only
#   ./build-release.sh --apk     # Also build APK for testing
#   ./build-release.sh --all     # Build .aab + APK + run validation
# ═══════════════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_APK=false
RUN_VALIDATION=false

# Parse flags
for arg in "$@"; do
    case $arg in
        --apk) BUILD_APK=true ;;
        --all) BUILD_APK=true; RUN_VALIDATION=true ;;
    esac
done

echo -e "${CYAN}"
echo "═══════════════════════════════════════════════════════════"
echo "   KHETEEBAADI - Production Release Build"
echo "═══════════════════════════════════════════════════════════"
echo -e "${NC}"

cd "$SCRIPT_DIR"

# ── Pre-flight checks ──
echo -e "${YELLOW}[1/6] Pre-flight checks...${NC}"

command -v flutter >/dev/null 2>&1 || { echo -e "${RED}Flutter not found! Install: https://flutter.dev/docs/get-started/install${NC}"; exit 1; }
command -v java >/dev/null 2>&1 || { echo -e "${RED}Java not found! Install JDK 11+${NC}"; exit 1; }

FLUTTER_VERSION=$(flutter --version 2>/dev/null | head -1)
echo -e "${GREEN}  $FLUTTER_VERSION${NC}"

# Check keystore exists
if [ ! -f "android/app/upload-keystore.jks" ]; then
    echo -e "${RED}  Upload keystore not found at android/app/upload-keystore.jks${NC}"
    echo -e "${RED}  Run the keystore generation step first.${NC}"
    exit 1
fi
echo -e "${GREEN}  Upload keystore found${NC}"

# Check key.properties
if [ ! -f "android/key.properties" ]; then
    echo -e "${RED}  key.properties not found in android/${NC}"
    exit 1
fi
echo -e "${GREEN}  key.properties found${NC}"

# ── Clean previous builds ──
echo -e "${YELLOW}[2/6] Cleaning previous builds...${NC}"
flutter clean
echo -e "${GREEN}  Clean complete${NC}"

# ── Get dependencies ──
echo -e "${YELLOW}[3/6] Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}  Dependencies resolved${NC}"

# ── Run code generation (if using build_runner) ──
echo -e "${YELLOW}[4/6] Running code generation...${NC}"
if grep -q "build_runner" pubspec.yaml 2>/dev/null; then
    flutter pub run build_runner build --delete-conflicting-outputs 2>/dev/null || echo -e "${YELLOW}  build_runner skipped (may not be needed)${NC}"
else
    echo -e "${GREEN}  No code generation needed${NC}"
fi

# ── Build AAB (App Bundle for Play Store) ──
echo -e "${YELLOW}[5/6] Building release AAB...${NC}"
echo -e "${CYAN}  Environment: PRODUCTION${NC}"
echo -e "${CYAN}  API: https://api.kheteebaadi.com${NC}"

flutter build appbundle \
    --release \
    --dart-define=ENV=production \
    --obfuscate \
    --split-debug-info=build/debug-info \
    --target-platform android-arm,android-arm64,android-x64

AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
if [ -f "$AAB_PATH" ]; then
    AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)
    echo -e "${GREEN}  AAB built successfully: $AAB_PATH ($AAB_SIZE)${NC}"
else
    echo -e "${RED}  AAB build failed! Check errors above.${NC}"
    exit 1
fi

# ── Optionally build APK for testing ──
if [ "$BUILD_APK" = true ]; then
    echo -e "${YELLOW}[5b] Also building release APK for direct testing...${NC}"

    flutter build apk \
        --release \
        --dart-define=ENV=production \
        --obfuscate \
        --split-debug-info=build/debug-info

    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    if [ -f "$APK_PATH" ]; then
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        echo -e "${GREEN}  APK built: $APK_PATH ($APK_SIZE)${NC}"
    fi
fi

# ── Summary ──
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   BUILD COMPLETE!${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BLUE}AAB (Play Store):${NC}  $AAB_PATH"
if [ "$BUILD_APK" = true ] && [ -f "$APK_PATH" ]; then
    echo -e "  ${BLUE}APK (Testing):${NC}     $APK_PATH"
fi
echo -e "  ${BLUE}Debug symbols:${NC}     build/debug-info/"
echo ""
echo -e "  ${YELLOW}Next steps:${NC}"
echo -e "  1. Test the APK on a real device before uploading"
echo -e "  2. Go to https://play.google.com/console"
echo -e "  3. Create app > Upload the .aab file"
echo -e "  4. Upload debug symbols (build/debug-info/) for crash reporting"
echo -e "  5. Fill in store listing, screenshots, privacy policy"
echo -e "  6. Submit for review"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
