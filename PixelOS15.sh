#!/bin/bash

# =====================================================================
# 📱 PixelOS (Android 15) Production Script
# =====================================================================
# ⚙️ Target Device: OnePlus Nord N100 (billie2)
# 🔄 Base Source: Pre-Modified Manual Trees for PixelOS A15 (bp1a/ap2a)
# 💻 Environment: Cloud Optimized for Crave.io Workspace (No Clean)
# 👤 Maintainer: Sohaib
# =====================================================================

# ---------------------------------------------------------------------
# 1. ENVIRONMENT CONFIGURATION & GLOBAL VARIABLES
# ---------------------------------------------------------------------
echo "⚙️ PixelOS Android 15 environment parameters set kar rahe hain..."
export DEVICE="billie2"
export BUILD_USERNAME="sohaib"
export BUILD_HOSTNAME="crave"
export SKIP_ABI_CHECKS=true

# Terminal ke liye UTF-8 encoding force karna
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Output folder pehle se hi bana lena
mkdir -p out/target/product/${DEVICE}/

# ---------------------------------------------------------------------
# 2. PRE-SYNC WORKSPACE PURGE & CLEANUP
# ---------------------------------------------------------------------
echo "🧹 Purane zip aur img files ko safely delete kar rahe hain..."
rm -rf out/target/product/${DEVICE}/*.zip
rm -rf out/target/product/${DEVICE}/*.img
rm -rf .repo/local_manifests .repo/manifests .repo/manifest.xml

echo "🔥 Git conflicts se bachne ke liye purane device trees ko uda rahe hain..."
rm -rf device/oneplus/billie2
rm -rf vendor/oneplus/billie2
rm -rf kernel/oneplus/sm4250
rm -rf hardware/oneplus
rm -rf device/qcom/sepolicy_vndr

# ---------------------------------------------------------------------
# 3. PIXELOS SOURCE INITIALIZATION & SYNCHRONIZATION
# ---------------------------------------------------------------------
echo "⚙️ Upstream PixelOS Android 15 manifest initialize kar rahe hain..."
repo init --depth=1 -u https://github.com/PixelOS-AOSP/manifest.git -b fifteen --git-lfs

echo "⚡ Crave fabric ke zariye high-speed sync run kar rahe hain..."
/opt/crave/resync.sh

# ---------------------------------------------------------------------
# 4. FETCHING YOUR VERIFIED CUSTOM PRODUCTION TREES
# ---------------------------------------------------------------------
echo "📂 Aapka MANUALLY MODIFIED PixelOS device tree download ho raha hai..."
git clone https://github.com/sohaibdevelop1290-oss/android_device_oneplus_billie2.git -b PixelOS15 device/oneplus/billie2

echo "📂 Vendor blobs (Lineage 22.1) repository clone ho rahi hai..."
git clone https://github.com/sohaibdevelop1290-oss/proprietary_vendor_oneplus_billie2 -b lineage-22.1 vendor/oneplus/billie2

echo "📂 Linux kernel 4.19 architecture tree clone ho raha hai..."
git clone https://github.com/LineageOS/android_kernel_oneplus_sm4250 -b lineage-22.1 kernel/oneplus/sm4250

echo "📂 Hardware implementation layers clone ho rahe hain..."
git clone https://github.com/LineageOS/android_hardware_oneplus -b lineage-22.1 hardware/oneplus

echo "📂 Qualcomm legacy sepolicy structures fetch kar rahe hain..."
git clone https://github.com/sohaibdevelop1290-oss/android_device_qcom_sepolicy_vndr.git -b lineage-22.1-legacy-um device/qcom/sepolicy_vndr

# ---------------------------------------------------------------------
# 5. COMPILATION INITIATION (Direct Target Execution)
# ---------------------------------------------------------------------
echo "🔧 Build environment setup kar rahe hain..."
. build/envsetup.sh

echo "🚀 Target select kar rahe hain: pixelos_billie2-bp1a-userdebug"
lunch pixelos_billie2-bp1a-userdebug

# ---------------------------------------------------------------------
# ⭐ SAFE CONFLICT RESOLUTION (CRAVE-APPROVED)
# ---------------------------------------------------------------------
echo "🧹 Running 'make installclean' to safely wipe old LineageOS artifacts..."
make installclean

echo "🧱 Starting PixelOS Android 15 production compilation..."
mka bacon

# ---------------------------------------------------------------------
# 6. POST-BUILD ARTIFACT CAPTURE & EXPORT
# ---------------------------------------------------------------------
echo "📍 Final flashable zip aur images process ho rahi hain..."
ROM_DIR="out/target/product/${DEVICE}"
NOW=$(date +"%Y%m%d-%H%M")

# super_empty.img ko intercept aur protect karna
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

# Pixeldrain Upload Function
upload_to_pixeldrain() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        local response=$(curl -s -F "file=@$file_path" https://pixeldrain.com/api/file)
        local file_id=$(echo "$response" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
        [ -n "$file_id" ] && echo "🌐 [PIXELDRAIN] Link: https://pixeldrain.com/u/$file_id"
    fi
}

if [ -f "$FINAL_ROM_ZIP" ]; then
    echo "📦 Flashable PixelOS Android 15 Package upload ho raha hai..."
    upload_to_pixeldrain "$FINAL_ROM_ZIP"
fi

if [ -f "$PROTECTED_SUPER_ZIP" ]; then
    echo "📦 Super Empty Image Archive upload ho raha hai..."
    upload_to_pixeldrain "$PROTECTED_SUPER_ZIP"
fi

echo "🏁 [SUCCESS] PixelOS Android 15 pipeline completed successfully!"
