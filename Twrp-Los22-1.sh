#!/bin/bash

# =====================================================================
# 📱 LineageOS 22.1 + TWRP Integrated Build Script
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

# TWRP Recovery Global Build Flags
export ALLOW_MISSING_DEPENDENCIES=true
export TW_DEFAULT_LANGUAGE="en"
export RECOVERY_VARIANT="twrp"

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

echo "🔥 [CRUCIAL] Clearing target repository source trees to block Git checkout failures..."
rm -rf device/oneplus/billie2
rm -rf vendor/oneplus/billie2
rm -rf kernel/oneplus/sm4250
rm -rf hardware/oneplus
rm -rf bootable/recovery

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

# ---------------------------------------------------------------------
# 4.1. AUTO-PATCHING TWRP FLAGS INTO BoardConfig.mk
# ---------------------------------------------------------------------
BOARD_CONFIG="device/oneplus/billie2/BoardConfig.mk"

if [ -f "$BOARD_CONFIG" ]; then
    echo "📝 Injecting TWRP Recovery Flags directly into BoardConfig.mk..."
    cat << 'EOF' >> "$BOARD_CONFIG"

# ==========================================
# AUTO-INJECTED TWRP RECOVERY CONFIGURATION
# ==========================================
TARGET_RECOVERY_GUI_VERSION := 720p
TW_THEME := portrait_mdpi
TW_EXTRA_LANGUAGES := true
TW_INPUT_BLACKLIST := "hbtp_vm"
RECOVERY_SDCARD_ON_DATA := true
TW_EXCLUDE_DEFAULT_USB_INIT := true
EOF
    echo "✅ BoardConfig.mk patched successfully!"
else
    echo "⚠️ Warning: BoardConfig.mk not found at expected path!"
fi

# ---------------------------------------------------------------------
# 4.2. TWRP RECOVERY INTEGRATION (OFFICIAL ANDROID 14.1 BASE)
# ---------------------------------------------------------------------
echo "🔥 Removing default LineageOS recovery and embedding TWRP source (android-14.1)..."
rm -rf bootable/recovery
git clone https://github.com/TeamWin/android_bootable_recovery -b android-14.1 bootable/recovery

# ---------------------------------------------------------------------
# 5. COMPILATION INITIATION
# ---------------------------------------------------------------------
echo "🔧 Setting up cross-compilation toolchain and environment variables..."
. build/envsetup.sh

echo "🚀 Starting full target production build with TWRP (mka bacon)..."
breakfast billie2 userdebug && mka bacon

# ---------------------------------------------------------------------
# 6. POST-BUILD ARTIFACT PROCESSING & SECURE CLOUD EXPORT
# ---------------------------------------------------------------------
echo "📍 Processing finalized flashable artifacts..."
NOW=$(date +"%Y%m%d-%H%M")
ROM_DIR="out/target/product/${DEVICE}"

FLASHABLE_ZIP=$(find "$ROM_DIR" -maxdepth 1 -name "lineage-22.1-*.zip" | grep -v "ota" | tail -n 1)

# Renaming output file with execution timestamp
if [ -f "$FLASHABLE_ZIP" ]; then
    mv "$FLASHABLE_ZIP" "${FLASHABLE_ZIP%.zip}-${NOW}.zip"
    FINAL_ROM_ZIP="${FLASHABLE_ZIP%.zip}-${NOW}.zip"
fi

# 🏢 PROFESSIONAL CLOUD UPLOAD CONTROLLER
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
    echo "📦 Exporting Flashable ROM Zip Package..."
    upload_to_gofile "$FINAL_ROM_ZIP"
else
    echo "⚠️ Flashable ROM Zip file not found!"
fi

echo "🏁 [SUCCESS] Full build execution lifecycle finalized cleanly!"

