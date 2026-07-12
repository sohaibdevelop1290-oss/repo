#!/bin/bash

# =====================================================================
# 📱 LineageOS Optimized Build Script - HARDWARE & RECOVERY FIX EDITION
# =====================================================================
# ⚙️ Target Device: OnePlus Nord N100 (billie2)
# 🔒 Build Phase: Android 15 (LineageOS 22.1) Stable Phase
# 💻 Environment: Cloud Optimized for Crave.io Workspace
# 👤 Maintainer: Sohaib
# =====================================================================

# ---------------------------------------------------------------------
# 1. ENVIRONMENT CONFIGURATION & GLOBAL VARIABLES
# ---------------------------------------------------------------------
echo "⚙️ Configuring build environment parameters..."
export DEVICE="billie2"
export BUILD_USERNAME="sohaib"
export BUILD_HOSTNAME="crave"
export SKIP_ABI_CHECKS=true

# Force UTF-8 Terminal Encoding to prevent broken characters
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Create output structure preemptively
mkdir -p out/target/product/${DEVICE}/

# ---------------------------------------------------------------------
# 2. PRE-SYNC WORKSPACE PURGE & CLEANUP
# ---------------------------------------------------------------------
echo "🧹 Safely purging active target directory artifacts to secure disk space..."
rm -rf out/target/product/${DEVICE}/*.zip
rm -rf out/target/product/${DEVICE}/*.img

echo "🧹 Clearing legacy manifest files and lock mechanisms..."
rm -rf .repo/local_manifests
rm -rf .repo/manifests
rm -rf .repo/manifest.xml

echo "🗑️ Dropping legacy target security policy definitions..."
rm -rf device/qcom/sepolicy_vndr

echo "🔥 [CRUCIAL] Clearing target repository source trees to block Git checkout failures..."
rm -rf device/oneplus/billie2
rm -rf vendor/oneplus/billie2
rm -rf kernel/oneplus/sm4250
rm -rf hardware/oneplus

# ---------------------------------------------------------------------
# 3. SOURCE TREE INITIALIZATION & MANIFEST SYNCHRONIZATION
# ---------------------------------------------------------------------
echo "⚙️ Initializing upstream LineageOS Android platform source tree..."
repo init --depth=1 -u https://github.com/LineageOS/android.git -b lineage-22.1 --git-lfs

echo "⚡ Executing high-speed safe workspace synchronization via Crave fabric..."
/opt/crave/resync.sh

echo "🔄 Running requested repo sync command..."
repo sync
# ---------------------------------------------------------------------
# 4. REMOTE TREES CLONING & DEPENDENCY MANAGEMENT
# ---------------------------------------------------------------------
echo "📂 Fetching device tree configuration..."
git clone https://github.com/LineageOS/android_device_oneplus_billie2 -b lineage-22.1 device/oneplus/billie2

echo "📂 Fetching proprietary vendor blob repositories..."
git clone https://github.com/sohaibdevelop1290-oss/proprietary_vendor_oneplus_billie2 -b lineage-22.1 vendor/oneplus/billie2

echo "📂 Fetching target platform Linux kernel architecture tree..."
git clone https://github.com/LineageOS/android_kernel_oneplus_sm4250 -b lineage-22.1 kernel/oneplus/sm4250

echo "📂 Fetching vendor hardware implementation layers..."
git clone https://github.com/LineageOS/android_hardware_oneplus -b lineage-22.1 hardware/oneplus

echo "📂 Fetching legacy Qualcomm platform security policy structures..."
git clone https://github.com/sohaibdevelop1290-oss/android_device_qcom_sepolicy_vndr.git -b lineage-22.1-legacy-um device/qcom/sepolicy_vndr

# ---------------------------------------------------------------------
# 5. COMPILATION INITIATION & DEEP TARGET IMAGE ARREST
# ---------------------------------------------------------------------
echo "🔧 Setting up cross-compilation toolchain and environment variables..."
. build/envsetup.sh

echo "🚀 Starting full target production build (mka bacon)..."
breakfast billie2 userdebug && mka bacon

# ---------------------------------------------------------------------
# 6. INSTANT IMAGE ARREST BLOCK (Saves super_empty.img from Auto-Deletion)
# ---------------------------------------------------------------------
echo "🔒 Triggering immediate target file inspection and capture..."
ROM_DIR="out/target/product/${DEVICE}"

# Locating and wrapping the build intermediate super_empty.img into a safe ZIP archive instantly
find "${ROM_DIR}/obj/PACKAGING/" -name "super_empty.img" -exec zip -j "${ROM_DIR}/super_empty_protected.zip" {} \;

if [ -f "${ROM_DIR}/super_empty_protected.zip" ]; then
    echo "✅ Success: super_empty.img captured and locked before Crave storage flush!"
else
    echo "⚠️ Warning: super_empty.img could not be intercepted inside intermediate files."
fi

# ---------------------------------------------------------------------
# 7. POST-BUILD ARTIFACT PROCESSING & SECURE CLOUD EXPORT
# ---------------------------------------------------------------------
echo "📍 Processing finalized flashable artifacts..."
NOW=$(date +"%Y%m%d-%H%M")

FLASHABLE_ZIP=$(find "$ROM_DIR" -maxdepth 1 -name "lineage-22.1-*.zip" | grep -v "ota" | tail -n 1)
OTA_ZIP=$(find "$ROM_DIR" -maxdepth 1 -name "lineage_billie2-ota-*.zip" | tail -n 1)
PROTECTED_SUPER_ZIP="${ROM_DIR}/super_empty_protected.zip"

# Appending execution timestamp to outputs
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

# Execution of Exports
if [ -f "$FINAL_ROM_ZIP" ]; then
    echo "📦 Exporting Flashable ROM Package..."
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
