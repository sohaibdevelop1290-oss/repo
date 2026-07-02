#!/bin/bash

# =====================================================================
# 📱 PixelOS (Android 15) Dynamic Auto-Detection Production Script
# =====================================================================
# ⚙️ Target Device: OnePlus Nord N100 (billie2)
# 🔄 Base Source: Pre-Modified Manual Trees for PixelOS A15 (bp1a/ap2a)
# 💻 Environment: Cloud Optimized for Crave.io Workspace (No Clean)
# 👤 Maintainer: Sohaib
# =====================================================================

# ---------------------------------------------------------------------
# 1. ENVIRONMENT CONFIGURATION & GLOBAL VARIABLES
# ---------------------------------------------------------------------
echo "⚙️ Configuring PixelOS Android 15 environment parameters..."
export DEVICE="billie2"
export BUILD_USERNAME="sohaib"
export BUILD_HOSTNAME="crave"
export SKIP_ABI_CHECKS=true

# Force UTF-8 Terminal Encoding
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Create output structure preemptively
mkdir -p out/target/product/${DEVICE}/

# ---------------------------------------------------------------------
# 2. PRE-SYNC WORKSPACE PURGE & CLEANUP
# ---------------------------------------------------------------------
echo "🧹 Safely purging active target directory artifacts..."
rm -rf out/target/product/${DEVICE}/*.zip
rm -rf out/target/product/${DEVICE}/*.img
rm -rf .repo/local_manifests .repo/manifests .repo/manifest.xml

echo "🔥 Clearing target repository source trees to block Git conflicts..."
rm -rf device/oneplus/billie2
rm -rf vendor/oneplus/billie2
rm -rf kernel/oneplus/sm4250
rm -rf hardware/oneplus
rm -rf device/qcom/sepolicy_vndr

# ---------------------------------------------------------------------
# 3. PIXELOS SOURCE INITIALIZATION & SYNCHRONIZATION
# ---------------------------------------------------------------------
echo "⚙️ Initializing upstream PixelOS Android 15 platform source tree..."
repo init --depth=1 -u https://github.com/PixelOS-AOSP/manifest.git -b fifteen --git-lfs

echo "⚡ Executing high-speed safe workspace synchronization via Crave fabric..."
/opt/crave/resync.sh

# ---------------------------------------------------------------------
# 4. FETCHING YOUR VERIFIED CUSTOM PRODUCTION TREES
# ---------------------------------------------------------------------
echo "📂 Fetching your MANUALLY MODIFIED PixelOS device tree..."
git clone https://github.com/sohaibdevelop1290-oss/android_device_oneplus_billie2.git -b PixelOS15 device/oneplus/billie2

echo "📂 Fetching your proprietary vendor blob repositories (Lineage 22.1)..."
git clone https://github.com/sohaibdevelop1290-oss/proprietary_vendor_oneplus_billie2 -b lineage-22.1 vendor/oneplus/billie2

echo "📂 Fetching your platform Linux kernel architecture tree (Lineage 22.1)..."
git clone https://github.com/LineageOS/android_kernel_oneplus_sm4250 -b lineage-22.1 kernel/oneplus/sm4250

echo "📂 Fetching vendor hardware implementation layers (Lineage 22.1)..."
git clone https://github.com/LineageOS/android_hardware_oneplus -b lineage-22.1 hardware/oneplus

echo "📂 Fetching Qualcomm platform legacy sepolicy structures..."
git clone https://github.com/sohaibdevelop1290-oss/android_device_qcom_sepolicy_vndr.git -b lineage-22.1-legacy-um device/qcom/sepolicy_vndr

# ---------------------------------------------------------------------
# 5. COMPILATION INITIATION (Smart Lunch Auto-Detection Engine)
# ---------------------------------------------------------------------
echo "🔧 Setting up compilation environment variables..."
. build/envsetup.sh

echo "🔍 Detecting your device tree configuration style..."
DT_DIR="device/oneplus/billie2"

if [ -f "${DT_DIR}/aosp_billie2.mk" ]; then
    echo "💡 [DETECTED] Your tree uses AOSP prefix. Setting target to aosp_billie2..."
    LUNCH_TARGET="aosp_billie2-bp1a-userdebug"
elif [ -f "${DT_DIR}/pixelos_billie2.mk" ]; then
    echo "💡 [DETECTED] Your tree uses PixelOS prefix. Setting target to pixelos_billie2..."
    LUNCH_TARGET="pixelos_billie2-bp1a-userdebug"
else
    echo "⚠️ [WARNING] Specific makefile not found. Falling back to official GitHub recommendation..."
    LUNCH_TARGET="aosp_billie2-bp1a-userdebug"
fi

echo "🚀 Starting PixelOS Android 15 production build with target: ${LUNCH_TARGET}"
lunch ${LUNCH_TARGET} && mka bacon

# ---------------------------------------------------------------------
# 6. POST-BUILD ARTIFACT CAPTURE & EXPORT
# ---------------------------------------------------------------------
echo "📍 Processing finalized flashable PixelOS artifacts..."
ROM_DIR="out/target/product/${DEVICE}"
NOW=$(date +"%Y%m%d-%H%M")

# Intercept and protect the critical dynamic map image table
find "${ROM_DIR}/obj/PACKAGING/" -name "super_empty.img" -exec zip -j "${ROM_DIR}/super_empty_protected.zip" {} \;

if [ -f "${ROM_DIR}/super_empty_protected.zip" ]; then
    mv "${ROM_DIR}/super_empty_protected.zip" "$ROM_DIR/super_empty_protected-${NOW}.zip"
    PROTECTED_SUPER_ZIP="$ROM_DIR/super_empty_protected-${NOW}.zip"
fi

FINAL_ZIP=$(find "$ROM_DIR" -maxdepth 1 -name "PixelOS_*.zip" -o -name "pixelos_*.zip" | grep -v "ota" | tail -n 1)
if [ -f "$FINAL_ZIP" ]; then
    mv "$FINAL_ZIP" "${FINAL_ZIP%.zip}-${NOW}.zip"
    FINAL_ROM_ZIP="${FINAL_ZIP%.zip}-${NOW}.zip"
fi

# Upload Module Controllers
upload_to_pixeldrain() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        local response=$(curl -s -F "file=@$file_path" https://pixeldrain.com/api/file)
        local file_id=$(echo "$response" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
        [ -n "$file_id" ] && echo "🌐 [PIXELDRAIN] Link: https://pixeldrain.com/u/$file_id"
    fi
}

if [ -f "$FINAL_ROM_ZIP" ]; then
    echo "📦 Exporting Flashable PixelOS Android 15 Package..."
    upload_to_pixeldrain "$FINAL_ROM_ZIP"
fi

if [ -f "$PROTECTED_SUPER_ZIP" ]; then
    echo "📦 Exporting Intercepted Super Empty Image Archive..."
    upload_to_pixeldrain "$PROTECTED_SUPER_ZIP"
fi

echo "🏁 [SUCCESS] PixelOS Android 15 migration pipeline finalized!"
