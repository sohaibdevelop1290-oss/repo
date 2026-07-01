#!/bin/bash

# ==================================
# 📱 LineageOS Optimized Build Script - PROPS SPLIT EDITION
# 🛠️ For: billie2 (OnePlus Nord N100 - Android 13)
# 🔒 Phase 1 - Part 2: Deep Partition Capture & Safe Cloud Protection
# 💻 Optimized for Crave.io
# ==================================

# Setup device variables early
export DEVICE="billie2"
export BUILD_USERNAME="sohaib"
export BUILD_HOSTNAME="crave"
export SKIP_ABI_CHECKS=true

# --- 🧹 Smart Cache Setup (Only targets current flashable outputs) ---
echo "🧹 Safely clearing target directory artifacts to save space..."
rm -rf out/target/product/${DEVICE}/*.zip
rm -rf out/target/product/${DEVICE}/*.img

# --- 🧹 Safe Local Manifest Cleanup ---
echo "🧹 Removing old manifests..."
rm -rf .repo/local_manifests
rm -rf .repo/manifests
rm -rf .repo/manifest.xml

# --- 🗑️ Safe Device Settings Reset ---
echo "🗑️ Clearing legacy device configuration paths..."
rm -rf device/qcom/sepolicy_vndr

# =====================================================================
# 🔥 CRUCIAL SYNC FIX: Pre-emptively removing folders to prevent Git conflict
# =====================================================================
echo "🧹 Removing default directories before sync to avoid unsupported checkout state..."
rm -rf device/oneplus/billie2
rm -rf vendor/oneplus/billie2
rm -rf kernel/oneplus/sm4250
rm -rf hardware/oneplus

# --- ⚙️ Init ROM repo ---
echo "⚙️ Initializing LineageOS source tree..."
repo init --depth=1 -u https://github.com/LineageOS/android.git -b lineage-20.0 --git-lfs

# --- ⚡ Safe Crave Sync ---
echo "⚡ Synchronizing remote source repositories using Crave protocol..."
/opt/crave/resync.sh

# --- 📂 Clone Device, Vendor, Kernel & Hardware Trees ---
echo "📂 Fetching device configuration tree..."
git clone https://github.com/LineageOS/android_device_oneplus_billie2 -b lineage-20 device/oneplus/billie2

echo "📂 Fetching proprietary vendor blobs..."
git clone https://github.com/sohaibdevelop1290-oss/proprietary_vendor_oneplus_billie2 -b lineage-20 vendor/oneplus/billie2

echo "📂 Fetching source kernel tree..."
git clone https://github.com/LineageOS/android_kernel_oneplus_sm4250 -b lineage-20 kernel/oneplus/sm4250

echo "📂 Fetching hardware dependency layers..."
git clone https://github.com/LineageOS/android_hardware_oneplus -b lineage-20 hardware/oneplus

echo "📂 Fetching target platform security configurations..."
git clone https://github.com/sohaibdevelop1290-oss/android_device_qcom_sepolicy_vndr.git -b lineage-20.0-legacy-um device/qcom/sepolicy_vndr

echo "📂 Fetching MindTheGApps packages..."
rm -rf vendor/gapps
git clone https://gitlab.com/MindTheGapps/vendor_gapps.git -b sigma vendor/gapps

# --- 📶 Wi-Fi PTCL & Region Fix (Channel 12/13 Enable) ---
echo "📶 Injecting Wi-Fi regional fixes for PTCL & hidden routers..."
WIFI_INI=$(find device/oneplus/billie2/ vendor/oneplus/billie2/ -name "WCNSS_qcom_cfg.ini" | head -n 1)
if [ -n "$WIFI_INI" ] && [ -f "$WIFI_INI" ]; then
    sed -i 's/gCrpCc=.*/gCrpCc=00/g' "$WIFI_INI" 2>/dev/null || echo "gCrpCc=00" >> "$WIFI_INI"
    sed -i 's/gRegulatoryChangeCountry=.*/gRegulatoryChangeCountry=00/g' "$WIFI_INI" 2>/dev/null || echo "gRegulatoryChangeCountry=00" >> "$WIFI_INI"
    sed -i 's/gChannelBondingMode24GHz=.*/gChannelBondingMode24GHz=1/g' "$WIFI_INI" 2>/dev/null
fi

WIFI_OVERLAY="device/oneplus/billie2/overlay/frameworks/base/core/res/res/values/config.xml"
if [ -f "$WIFI_OVERLAY" ]; then
    sed -i 's/<string name="config_wifi_operating_country_code">.*<\/string>/<string name="config_wifi_operating_country_code"><\/string>/g' "$WIFI_OVERLAY"
fi

# --- ⚙️ GApps Integration (lineage_billie2.mk) ---
echo "🔗 Linking MindTheGApps to lineage_billie2.mk..."
PRODUCT_MK="device/oneplus/billie2/lineage_billie2.mk"
if [ -f "$PRODUCT_MK" ]; then
    echo "" >> "$PRODUCT_MK"
    echo "# Include GApps configuration layers" >> "$PRODUCT_MK"
    echo '$(call inherit-product-if-exists, vendor/gapps/arm64/arm64-vendor.mk)' >> "$PRODUCT_MK"
fi

# --- ⚙️ Custom App Exclusion (Lite GApps Enforcer) ---
GAPPS_CONFIG="vendor/gapps/config.mk"
if [ -f "$GAPPS_CONFIG" ]; then
    cat <<EOF >> "$GAPPS_CONFIG"
CUSTOM_KEEP_APPS := ChromeHomePageProvider GoogleExtServices GooglePackageInstaller GmsCore Phonesky Chrome YouTube Gmail2 LatinIMEGoogle Drive GoogleSearchBox Photos
PRODUCT_PACKAGES := \$(filter \$(CUSTOM_KEEP_APPS), \$(PRODUCT_PACKAGES))
EOF
fi

# --- 📺 Camera Color, Display & Video Playback Fixes (Props Split Fixed) ---
echo "📺 Injecting target properties into system.prop and vendor_prop layers..."
SYSTEM_PROP="device/oneplus/billie2/system.prop"
VENDOR_PROP="device/oneplus/billie2/vendor_prop"

# 1. Pure system-level properties
mkdir -p $(dirname "$SYSTEM_PROP")
cat <<EOF >> "$SYSTEM_PROP"
ro.hardware.egl=adreno
debug.sf.enable_hwc_vds=1
EOF

# 2. Pure vendor-level properties
mkdir -p $(dirname "$VENDOR_PROP")
cat <<EOF >> "$VENDOR_PROP"
vendor.display.enable_default_color_mode=1
persist.vendor.camera.privapp.list=com.android.camera,org.lineageos.snap
EOF

# --- 🛠️ Partition & Recovery Fixes (BoardConfig.mk) ---
BOARD_CONFIG="device/oneplus/billie2/BoardConfig.mk"
if [ -f "$BOARD_CONFIG" ]; then
    sed -i 's/BOARD_ONEPLUS_DYNAMIC_PARTITIONS_SIZE := .*/BOARD_ONEPLUS_DYNAMIC_PARTITIONS_SIZE := 6442450944/g' "$BOARD_CONFIG"
    
    cat <<EOF >> "$BOARD_CONFIG"

# Phase 1 Part 2 - Android 10 Transition Fixes
TARGET_RECOVERY_IGNORE_TIMESTAMP := true
BOARD_SUPPRESS_SECURE_ERASE := true
EOF
fi

# ==================================
# 🧱 Build Execution & DEEP INSTANT LOCK
# ==================================
echo "🔧 Setting up build environment setup..."
. build/envsetup.sh

mkdir -p $HOME/.local/lib
ln -sf /usr/lib/x86_64-linux-gnu/libncurses.so.6 $HOME/.local/lib/libncurses.so.5
ln -sf /usr/lib/x86_64-linux-gnu/libtinfo.so.6 $HOME/.local/lib/libtinfo.so.5
export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH

export WITH_GAPPS=true
mkdir -p out/target/product/${DEVICE}/

# 🔥 فکس: بلڈ ختم ہوتے ہی لاگ (Screenshot 2026-07-01 165623.png) والے اندرونی راستے سے امیج کو نکال کر فوراً زپ کرنا
echo "🚀 ===== Starting GApps Build with Target Files Search Lock ====="
breakfast billie2 userdebug && \
mka bacon && \
find out/target/product/${DEVICE}/obj/PACKAGING/ -name "super_empty.img" -exec zip -j out/target/product/${DEVICE}/super_empty_protected.zip {} \;

echo "🎉 ===== All builds and deep protections completed successfully! ====="

# ==================================
# 📦 Post-Build Artifact Handling
# ==================================
echo "📍 Processing build output artifacts..."
ROM_DIR="out/target/product/${DEVICE}"
NOW=$(date +"%Y%m%d-%H%M")

FLASHABLE_ZIP=$(find "$ROM_DIR" -maxdepth 1 -name "lineage-20.0-*.zip" | grep -v "ota" | tail -n 1)
OTA_ZIP=$(find "$ROM_DIR" -maxdepth 1 -name "lineage_billie2-ota-*.zip" | tail -n 1)

PROTECTED_SUPER_ZIP=$(find "$ROM_DIR" -maxdepth 1 -name "super_empty_protected.zip" | tail -n 1)

if [ -f "$PROTECTED_SUPER_ZIP" ]; then
    NEW_SUPER_ZIP="$ROM_DIR/super_empty_protected-${NOW}.zip"
    mv "$PROTECTED_SUPER_ZIP" "$NEW_SUPER_ZIP"
    PROTECTED_SUPER_ZIP="$NEW_SUPER_ZIP"
fi

# --- ☁️ Smart Dual Upload Implementations ---
upload_to_gofile() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        local server=$(curl -s https://api.gofile.io/servers | grep -o '"name":"[^"]*' | head -n 1 | grep -o '[^"]*$')
        if [ -n "$server" ]; then
            local response=$(curl -s -F "file=@$file_path" "https://${server}.gofile.io/uploadFile")
            local download_page=$(echo "$response" | sed -n 's/.*"downloadPage":"\([^"]*\)".*/\1/p')
            [ -n "$download_page" ] && echo "✅ Gofile Link: $download_page"
        fi
    fi
}

upload_to_pixeldrain() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        local response=$(curl -s -F "file=@$file_path" https://pixeldrain.com/api/file)
        local file_id=$(echo "$response" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
        [ -n "$file_id" ] && echo "✅ Pixeldrain Link: https://pixeldrain.com/u/$file_id"
    fi
}

# --- Trigger Upload Actions ---
if [ -f "$FLASHABLE_ZIP" ]; then
    NEW_FLASHABLE="${FLASHABLE_ZIP%.zip}-${NOW}.zip"
    mv "$FLASHABLE_ZIP" "$NEW_FLASHABLE"
    echo "📦 ROM Zip: $NEW_FLASHABLE"
    upload_to_gofile "$NEW_FLASHABLE"
    upload_to_pixeldrain "$NEW_FLASHABLE"
fi

if [ -f "$OTA_ZIP" ]; then
    NEW_OTA="${OTA_ZIP%.zip}-${NOW}.zip"
    mv "$OTA_ZIP" "$NEW_OTA"
    echo "📦 OTA Zip: $NEW_OTA"
    upload_to_gofile "$NEW_OTA"
    upload_to_pixeldrain "$NEW_OTA"
fi

if [ -f "$PROTECTED_SUPER_ZIP" ]; then
    echo "📦 Uploading Protected Super Empty Archive..."
    upload_to_gofile "$PROTECTED_SUPER_ZIP"
    upload_to_pixeldrain "$PROTECTED_SUPER_ZIP"
fi

echo "🏁 Phase 1 Part 2 Build script execution completed safely!"
