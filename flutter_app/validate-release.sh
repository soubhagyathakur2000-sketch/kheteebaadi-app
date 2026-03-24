#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# Kheteebaadi - Pre-Release Validation
# Run this BEFORE building to catch issues early.
#
# Usage: chmod +x validate-release.sh && ./validate-release.sh
# ═══════════════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check_pass() { echo -e "  ${GREEN}PASS${NC} $1"; PASS=$((PASS+1)); }
check_fail() { echo -e "  ${RED}FAIL${NC} $1"; FAIL=$((FAIL+1)); }
check_warn() { echo -e "  ${YELLOW}WARN${NC} $1"; WARN=$((WARN+1)); }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "   Kheteebaadi - Pre-Release Validation"
echo "═══════════════════════════════════════════════════════════"
echo ""

# ── 1. Tools ──
echo "Tools:"
command -v flutter >/dev/null 2>&1 && check_pass "Flutter SDK installed" || check_fail "Flutter SDK not found"
command -v java >/dev/null 2>&1 && check_pass "Java installed" || check_fail "Java not found"
command -v keytool >/dev/null 2>&1 && check_pass "keytool available" || check_warn "keytool not found"

# ── 2. Project files ──
echo ""
echo "Project files:"
[ -f "pubspec.yaml" ] && check_pass "pubspec.yaml exists" || check_fail "pubspec.yaml missing"
[ -f "lib/main.dart" ] && check_pass "lib/main.dart exists" || check_fail "lib/main.dart missing"
[ -d "android" ] && check_pass "android/ directory exists" || check_fail "android/ directory missing"
[ -f "android/app/build.gradle" ] && check_pass "android/app/build.gradle exists" || check_fail "build.gradle missing"

# ── 3. Signing ──
echo ""
echo "Signing configuration:"
[ -f "android/app/upload-keystore.jks" ] && check_pass "Upload keystore exists" || check_fail "Upload keystore MISSING - cannot sign release"
[ -f "android/key.properties" ] && check_pass "key.properties exists" || check_fail "key.properties MISSING"

if [ -f "android/key.properties" ]; then
    grep -q "storeFile" android/key.properties && check_pass "storeFile configured" || check_fail "storeFile not in key.properties"
    grep -q "keyAlias" android/key.properties && check_pass "keyAlias configured" || check_fail "keyAlias not in key.properties"
fi

# ── 4. Android Manifest ──
echo ""
echo "Android Manifest:"
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
    grep -q "INTERNET" "$MANIFEST" && check_pass "INTERNET permission" || check_fail "INTERNET permission missing"
    grep -q "ACCESS_FINE_LOCATION" "$MANIFEST" && check_pass "Location permission" || check_warn "Location permission missing"
    grep -q "CAMERA" "$MANIFEST" && check_pass "Camera permission" || check_warn "Camera permission missing"
    grep -q "RECORD_AUDIO" "$MANIFEST" && check_pass "Microphone permission" || check_warn "Microphone permission missing"
    grep -q "com.kheteebaadi.app" "$MANIFEST" && check_pass "Package name correct" || check_warn "Package name mismatch"
else
    check_fail "AndroidManifest.xml not found"
fi

# ── 5. App config ──
echo ""
echo "App configuration:"
if [ -f "lib/core/constants/api_constants.dart" ]; then
    if grep -q "10.0.2.2" "lib/core/constants/api_constants.dart"; then
        check_warn "Hardcoded localhost URL found (should use AppConfig)"
    else
        check_pass "No hardcoded localhost URLs"
    fi
fi

if [ -f "lib/core/config/app_config.dart" ]; then
    check_pass "AppConfig environment switcher exists"
    grep -q "production" "lib/core/config/app_config.dart" && check_pass "Production config defined" || check_fail "No production config"
else
    check_warn "AppConfig not found - base URL may be hardcoded"
fi

if [ -f "lib/core/constants/app_constants.dart" ]; then
    if grep -q "rzp_test_" "lib/core/constants/app_constants.dart"; then
        check_warn "Razorpay test key detected (pass --dart-define=RAZORPAY_KEY=rzp_live_xxx for prod)"
    fi
fi

# ── 6. Dependencies ──
echo ""
echo "Dependencies:"
if [ -f "pubspec.yaml" ]; then
    grep -q "flutter_riverpod" pubspec.yaml && check_pass "Riverpod (state management)" || check_warn "Riverpod not found"
    grep -q "dio:" pubspec.yaml && check_pass "Dio (HTTP client)" || check_warn "Dio not found"
    grep -q "go_router" pubspec.yaml && check_pass "GoRouter (navigation)" || check_warn "GoRouter not found"
    grep -q "hive:" pubspec.yaml && check_pass "Hive (local storage)" || check_warn "Hive not found"
    grep -q "drift:" pubspec.yaml && check_pass "Drift (SQLite)" || check_warn "Drift not found"
fi

# ── 7. Icons ──
echo ""
echo "App icons:"
for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
    ICON="android/app/src/main/res/mipmap-${density}/ic_launcher.png"
    [ -f "$ICON" ] && check_pass "Icon: $density" || check_warn "Missing icon: $density"
done

# ── 8. ProGuard ──
echo ""
echo "ProGuard:"
[ -f "android/app/proguard-rules.pro" ] && check_pass "ProGuard rules exist" || check_warn "No ProGuard rules (release may strip needed classes)"

# ── 9. Git status ──
echo ""
echo "Git:"
if command -v git >/dev/null 2>&1 && [ -d "../../.git" ] || [ -d ".git" ]; then
    # Check .gitignore covers secrets
    if [ -f "../../.gitignore" ]; then
        grep -q "key.properties" "../../.gitignore" && check_pass ".gitignore covers key.properties" || check_warn "key.properties NOT in .gitignore"
        grep -q "upload-keystore" "../../.gitignore" && check_pass ".gitignore covers keystore" || check_warn "keystore NOT in .gitignore"
        grep -q "\.env" "../../.gitignore" && check_pass ".gitignore covers .env" || check_warn ".env NOT in .gitignore"
    fi
fi

# ── Summary ──
echo ""
echo "═══════════════════════════════════════════════════════════"
echo -e "  Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}, ${YELLOW}$WARN warnings${NC}"
echo "═══════════════════════════════════════════════════════════"
echo ""

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}  Fix the failures above before building!${NC}"
    exit 1
elif [ $WARN -gt 0 ]; then
    echo -e "${YELLOW}  Warnings found - review before building.${NC}"
    echo -e "${GREEN}  You can proceed with: ./build-release.sh${NC}"
else
    echo -e "${GREEN}  All checks passed! Ready to build.${NC}"
    echo -e "${GREEN}  Run: ./build-release.sh${NC}"
fi
echo ""
