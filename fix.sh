#!/bin/bash
# ============================================
# RainLab.Deploy OpenSSL SHA256 Patch
# Version: 1.0.0
# License: MIT
# Fixes: "Could not contact beacon" on servers with OpenSSL 3.x
# Usage: Run from the root of any October CMS project
#   bash fix.sh
#
# Author: Łukasz 'Alien' Kosma — Pear Interactive
#         https://pear.pl | https://github.com/pearpl
# ============================================

VERSION="1.0.0"

set -e

DEPLOY_DIR="plugins/rainlab/deploy"

# Check if we're in an October CMS project
if [ ! -f "artisan" ] || [ ! -d "$DEPLOY_DIR" ]; then
    echo "❌ Error: Run this from the root of an October CMS project with RainLab.Deploy installed."
    exit 1
fi

echo "🔧 RainLab.Deploy SHA256 Patch v${VERSION}"
echo "   https://github.com/pearpl/Rainlab-Deploy-sha256-fix-for-October-CMS"
echo ""

# 1. Fix ServerKey.php — openssl_sign
FILE1="$DEPLOY_DIR/models/ServerKey.php"
if grep -q 'openssl_sign($data, $signature, $resource);' "$FILE1" 2>/dev/null; then
    sed -i.bak 's/openssl_sign($data, $signature, $resource);/openssl_sign($data, $signature, $resource, OPENSSL_ALGO_SHA256);/' "$FILE1"
    rm -f "$FILE1.bak"
    echo "  ✅ ServerKey.php — openssl_sign fixed"
else
    echo "  ⏭️  ServerKey.php — openssl_sign already patched or not found"
fi

# 2. Fix ServerKey.php — openssl_verify
if grep -q 'return openssl_verify($data, $sigBin, $resource);' "$FILE1" 2>/dev/null; then
    sed -i.bak 's/return openssl_verify($data, $sigBin, $resource);/return openssl_verify($data, $sigBin, $resource, OPENSSL_ALGO_SHA256);/' "$FILE1"
    rm -f "$FILE1.bak"
    echo "  ✅ ServerKey.php — openssl_verify fixed"
else
    echo "  ⏭️  ServerKey.php — openssl_verify already patched or not found"
fi

# 3. Fix beacon.stub — openssl_verify
FILE2="$DEPLOY_DIR/beacon/templates/app/bootstrap/beacon.stub"
if grep -q 'return openssl_verify($userPayload, $signatureDecoded, $pubKey) === 1;' "$FILE2" 2>/dev/null; then
    sed -i.bak 's/return openssl_verify($userPayload, $signatureDecoded, $pubKey) === 1;/return openssl_verify($userPayload, $signatureDecoded, $pubKey, OPENSSL_ALGO_SHA256) === 1;/' "$FILE2"
    rm -f "$FILE2.bak"
    echo "  ✅ beacon.stub — openssl_verify fixed"
else
    echo "  ⏭️  beacon.stub — openssl_verify already patched or not found"
fi

echo ""
echo "✅ Done! Now re-download the beacon ZIP from backend and re-upload to your server."
echo ""
echo "📝 Author: Łukasz 'Alien' Kosma — https://pear.pl"
echo "☕ If this saved you time: https://buycoffee.to/pearpl"

# Self-destruct
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
echo ""
read -r -p "🗑️  Delete this patch script? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    rm -f "$SCRIPT_PATH"
    echo "🧹 Script deleted."
else
    echo "📁 Script kept at: $SCRIPT_PATH"
fi
