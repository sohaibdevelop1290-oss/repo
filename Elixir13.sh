#!/bin/bash

# =====================================================================
# 📱 Project Elixir (Android 13 - Tiramisu) Production Script
# =====================================================================
# ⚙️ Target Device: OnePlus Nord N100 (billie2)
# 🔄 Base Source: Pre-Modified Manual Trees for Project Elixir A13 (Pure AOSP)
# 💻 Environment: Cloud Optimized for Crave.io Workspace (No Clean)
# 👤 Maintainer: Sohaib
# =====================================================================

# ---------------------------------------------------------------------
# 1. ENVIRONMENT CONFIGURATION & GLOBAL VARIABLES
# ---------------------------------------------------------------------
echo "⚙️ Setting up Project Elixir Android 13 environment parameters..."
export DEVICE="billie2"
export SKIP_ABI_CHECKS=true
export ROM_DIR=$(pwd) # Defines current working directory for safe asset output

# Force UTF-8 encoding for terminal compatibility
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Pre-create the output directory structure
mkdir -p out/target/product/${DEVICE}/

# ---------------------------------------------------------------------
# 2. PRE-SYNC WORKSPACE PURGE & CLEANUP
# ---------------------------------------------------------------------
echo "🧹 Safely removing old zip and image artifacts..."
rm -rf out/target/product/${DEVICE}/*.zip
rm -rf out/target/product/${DEVICE}/*.img
rm -rf .repo/local_manifests .repo/manifests .repo/manifest.xml

echo "🔥 Purging older device trees to prevent git conflicts..."
rm -rf device/oneplus/billie2
rm -rf vendor/oneplus/billie2
rm -rf kernel/oneplus/sm4250
rm -rf hardware/oneplus
rm -rf device/qcom/sepolicy_vndr
# Removed chromium-webview purge as requested ✅

# ---------------------------------------------------------------------
# 3. PROJECT ELIXIR SOURCE INITIALIZATION & SYNCHRONIZATION
# ---------------------------------------------------------------------
echo "⚙️ Initializing upstream Project Elixir Android 13 (Tiramisu) manifest..."
repo init --depth=1 -u https://github.com/Project-Elixir/manifest.git -b tiramisu --git-lfs

echo "⚡ Executing dual-sync mechanism (Crave Fabric + Manual Backup)..."
/opt/crave/resync.sh
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

# ---------------------------------------------------------------------
# 4. FETCHING CUSTOM PRODUCTION TREES
# ---------------------------------------------------------------------
echo "📂 Cloning manually modified Project Elixir device tree..."
git clone https://github.com/sohaibdevelop1290-oss/android_device_oneplus_billie2.git -b elixir13 device/oneplus/billie2

echo "📂 Cloning vendor blobs (Lineage 20) repository..."
git clone https://github.com/sohaibdevelop1290-oss/proprietary_vendor_oneplus_billie2 -b lineage-20 vendor/oneplus/billie2

echo "📂 Cloning Linux kernel 4.19 architecture tree..."
git clone https://github.com/LineageOS/android_kernel_oneplus_sm4250 -b lineage-20 kernel/oneplus/sm4250

echo "📂 Cloning hardware implementation layers..."
git clone https://github.com/LineageOS/android_hardware_oneplus -b lineage-20 hardware/oneplus

echo "📂 Fetching Qualcomm legacy sepolicy structures..."
rm -rf device/qcom/sepolicy_vndr
git clone https://github.com/sohaibdevelop1290-oss/android_device_qcom_sepolicy_vndr.git -b lineage-20.0-legacy-um device/qcom/sepolicy_vndr

# ---------------------------------------------------------------------
# 5. COMPILATION INITIATION (Android 13 Pure AOSP Target)
# ---------------------------------------------------------------------
echo "🔧 Setting up build environment..."
. build/envsetup.sh

echo "🚀 Selecting target via explicit Pure AOSP platform flags..."
lunch aosp_billie2-userdebug

# ---------------------------------------------------------------------
# 6. SAFE CONFLICT RESOLUTION (CRAVE-APPROVED)
# ---------------------------------------------------------------------
echo "🧹 Running 'make installclean' to safely wipe old cross-source targets..."
make installclean

echo "🧱 Starting Project Elixir Android 13 production compilation..."
mka bacon -jX

# ---------------------------------------------------------------------
# 7. INSTANT IMAGE ARREST BLOCK (Converts super_empty.img to ZIP Automatically)
# ---------------------------------------------------------------------
echo "🔒 Triggering immediate target file inspection and capture..."

TARGET_IMG=$(find "${ROM_DIR}/out/target/product/${DEVICE}/obj/PACKAGING/" -name "super_empty.img" | head -n 1)

if [ -n "$TARGET_IMG" ] && [ -f "$TARGET_IMG" ]; then
    echo "📦 Found super_empty.img. Converting to zip archive automatically..."
    zip -j "${ROM_DIR}/out/target/product/${DEVICE}/super_empty_protected.zip" "$TARGET_IMG"
    echo "✅ Success: super_empty.img converted and locked before Crave storage flush!"
else
    echo "⚠️ Warning: super_empty.img could not be located in intermediate files."
fi

# ---------------------------------------------------------------------
# 8. POST-BUILD ARTIFACT PROCESSING & SECURE CLOUD EXPORT
# ---------------------------------------------------------------------
echo "📍 Processing finalized flashable artifacts..."
NOW=$(date +"%Y%m%d-%H%M")

cd out/target/product/${DEVICE}/

FLASHABLE_ZIP=$(find . -maxdepth 1 -name "ProjectElixir_*.zip" -o -name "projectelixir_*.zip" -o -name "aosp_*.zip" | grep -v "ota" | tail -n 1)
OTA_ZIP=$(find . -maxdepth 1 -name "ProjectElixir_*-ota-*.zip" -o -name "aosp_*-ota-*.zip" | tail -n 1)
PROTECTED_SUPER_ZIP="./super_empty_protected.zip"

if [ -f "$PROTECTED_SUPER_ZIP" ]; then
    mv "$PROTECTED_SUPER_ZIP" "./super_empty_protected-${NOW}.zip"
    FINAL_SUPER_ZIP="$(pwd)/super_empty_protected-${NOW}.zip"
fi

if [ -f "$FLASHABLE_ZIP" ]; then
    mv "$FLASHABLE_ZIP" "${FLASHABLE_ZIP%.zip}-${NOW}.zip"
    FINAL_ROM_ZIP="$(pwd)/${FLASHABLE_ZIP%.zip}-${NOW}.zip"
fi

if [ -f "$OTA_ZIP" ]; then
    mv "$OTA_ZIP" "${OTA_ZIP%.zip}-${NOW}.zip"
    FINAL_OTA_ZIP="$(pwd)/${OTA_ZIP%.zip}-${NOW}.zip"
fi

# 🏢 PROFESSIONAL CLOUD UPLOAD CONTROLLERS
upload_to_gofile() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        local server=$(curl -s https://api.gofile.io/servers | grep -o '"name":"[^"]*' | head -n 1 | grep -o '[^"]*$')
        if [ -n "$server" ]; then
            local response=$(curl -s -F "file=@$file_path" "https://${server}.gofile.io/uploadFile")
            local download_page=$(echo "$response" | sed -n 's/.*"downloadPage":"\([^"]*\)".*/\1/p')
            [ -n "$download_page" ] && echo "🌐 [GOFILE] Link: $download_page"
        fi
    fi
}

if [ -f "$FINAL_ROM_ZIP" ]; then
    echo "📦 Exporting Flashable ROM Package..."
    upload_to_gofile "$FINAL_ROM_ZIP"
fi

if [ -f "$FINAL_OTA_ZIP" ]; then
    echo "📦 Exporting OTA Update Package..."
    upload_to_gofile "$FINAL_OTA_ZIP"
fi

if [ -f "$FINAL_SUPER_ZIP" ]; then
    echo "📦 Exporting Intercepted Super Empty Image Archive..."
    upload_to_gofile "$FINAL_SUPER_ZIP"
fi

echo "🏁 [SUCCESS] Full build execution lifecycle finalized cleanly!"
