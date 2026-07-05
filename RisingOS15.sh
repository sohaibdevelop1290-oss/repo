#!/bin/bash

# =====================================================================
# 📱 RisingOS (Android 15 - Fifteen) Production Script
# =====================================================================
# ⚙️ Target Device: OnePlus Nord N100 (billie2)
# 🔄 Base Source: RisingOS Revived Source (Lineage 22.1 Architecture)
# 💻 Environment: Cloud Optimized for Crave.io Workspace (No Clean)
# 👤 Maintainer: Sohaib
# =====================================================================

# ---------------------------------------------------------------------
# 1. ENVIRONMENT CONFIGURATION & GLOBAL VARIABLES
# ---------------------------------------------------------------------
echo "⚙️ Setting up RisingOS Android 15 environment parameters..."
export DEVICE="billie2"
export SKIP_ABI_CHECKS=true

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

# ---------------------------------------------------------------------
# 3. RISINGOS SOURCE INITIALIZATION & SYNCHRONIZATION
# ---------------------------------------------------------------------
echo "⚙️ Initializing upstream RisingOS Android 15 (Fifteen) manifest..."
repo init --depth=1 -u https://github.com/RisingOS-Revived/android.git -b fifteen --git-lfs

echo "⚡ Executing dual-sync mechanism (Crave Fabric + Manual Backup)..."
/opt/crave/resync.sh

echo "🔄 Running requested repo sync command..."
repo sync -c --no-clone-bundle --optimized-fetch --prune --force-sync -j$(nproc --all)

# ---------------------------------------------------------------------
# 4. FETCHING CUSTOM PRODUCTION TREES
# ---------------------------------------------------------------------
echo "📂 Cloning LineageOS 22.1 based device tree with RisingOS15 branch..."
# آپ کی بتائی ہوئی مخصوص ڈیوائس ٹری کمانڈ:
git clone https://github.com/sohaibdevelop1290-oss/android_device_oneplus_billie2.git -b RisingOS15 device/oneplus/billie2

echo "📂 Cloning vendor blobs (Lineage 22.1) repository..."
git clone https://github.com/sohaibdevelop1290-oss/proprietary_vendor_oneplus_billie2 -b lineage-22.1 vendor/oneplus/billie2

echo "📂 Cloning Linux kernel 4.19 architecture tree..."
git clone https://github.com/LineageOS/android_kernel_oneplus_sm4250 -b lineage-22.1 kernel/oneplus/sm4250

echo "📂 Cloning hardware implementation layers..."
git clone https://github.com/LineageOS/android_hardware_oneplus -b lineage-22.1 hardware/oneplus

echo "📂 Fetching Qualcomm legacy sepolicy structures..."
rm -rf device/qcom/sepolicy_vndr
git clone https://github.com/sohaibdevelop1290-oss/android_device_qcom_sepolicy_vndr.git -b lineage-22.1-legacy-um device/qcom/sepolicy_vndr

# ---------------------------------------------------------------------
# 5. COMPILATION INITIATION (RisingOS Environment Setup)
# ---------------------------------------------------------------------
echo "🔧 Setting up build environment..."
. build/envsetup.sh

echo "🚀 Selecting target via official riseup build platform configuration..."
riseup billie2 userdebug

# 🛠️ GMS Clocks Removal to keep RisingOS Stock SystemUI Clocks
echo "🧹 Removing GMS SystemUIClocks to use RisingOS stock clocks..."
rm -rf vendor/gms/common/packages/apps/SystemUIClocks


# ---------------------------------------------------------------------
# 6. SAFE CONFLICT RESOLUTION (CRAVE-APPROVED)
# ---------------------------------------------------------------------
echo "🧹 Running 'make installclean' to safely wipe old cross-source targets..."
make installclean

echo "🧱 Starting RisingOS Android 15 production compilation via rise b..."
rise b

# ---------------------------------------------------------------------
# 7. INSTANT IMAGE ARREST BLOCK (Converts super_empty.img to ZIP Automatically)
# ---------------------------------------------------------------------
echo "🔒 Triggering immediate target file inspection and capture..."

TARGET_IMG=$(find "${ROM_DIR}/obj/PACKAGING/" -name "super_empty.img" | head -n 1)

if [ -n "$TARGET_IMG" ] && [ -f "$TARGET_IMG" ]; then
    echo "📦 Found super_empty.img. Converting to zip archive automatically..."
    zip -j "${ROM_DIR}/super_empty_protected.zip" "$TARGET_IMG"
    echo "✅ Success: super_empty.img converted and locked before Crave storage flush!"
else
    echo "⚠️ Warning: super_empty.img could not be located in intermediate files."
fi

# ---------------------------------------------------------------------
# 8. POST-BUILD ARTIFACT PROCESSING & SECURE CLOUD EXPORT
# ---------------------------------------------------------------------
echo "📍 Processing finalized flashable artifacts..."
NOW=$(date +"%Y%m%d-%H%M")

FLASHABLE_ZIP=$(find "$ROM_DIR" -maxdepth 1 -name "RisingOS_*.zip" -o -name "rising_*.zip" -o -name "risingos_*.zip" -o -name "lineage_*.zip" | grep -v "ota" | tail -n 1)
OTA_ZIP=$(find "$ROM_DIR" -maxdepth 1 -name "rising_billie2-ota-*.zip" -o -name "RisingOS_billie2-ota-*.zip" | tail -n 1)
PROTECTED_SUPER_ZIP="$ROM_DIR/super_empty_protected.zip"

if [ -f "$PROTECTED_SUPER_ZIP" ]; then
    mv "$PROTECTED_SUPER_ZIP" "$ROM_DIR/super_empty_protected-${NOW}.zip"
    PROTECTED_SUPER_ZIP="$ROM_DIR/super_empty_protected-${NOW}.zip"
fi

if [ -f "$FLASHABLE_ZIP" ]; then
    mv "$FLASHABLE_ZIP" "${FLASHABLE_ZIP%.zip}-${NOW}.zip"
    FINAL_ROM_ZIP="${FLASHABLE_ZIP%.zip}-${NOW}.zip"
fi

if [ -f "$OTA_ZIP" ]; then
    mv "$OTA_ZIP" "${OTA_ZIP%.zip}-${NOW}.zip"
    FINAL_OTA_ZIP="${OTA_ZIP%.zip}-${NOW}.zip"
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
    echo "📦 Exporting Flashable RisingOS Package..."
    upload_to_gofile "$FINAL_ROM_ZIP"
fi

if [ -f "$FINAL_OTA_ZIP" ]; then
    echo "📦 Exporting OTA Update Package..."
    upload_to_gofile "$FINAL_OTA_ZIP"
fi

if [ -f "$PROTECTED_SUPER_ZIP" ]; then
    echo "📦 Exporting Intercepted Super Empty Image Archive..."
    upload_to_gofile "$PROTECTED_SUPER_ZIP"
fi

echo "🏁 [SUCCESS] Full build execution lifecycle finalized cleanly!"
