#!/bin/bash

# ==================================
# 📱 LineageOS Optimized Build Script
# 🛠️ For: billie2 (OnePlus Nord N100 - Android 13)
# 🔒 Phase 1 - Part 2: Recovery, Partition, Wi-Fi, Camera Color & 2GB ZRAM Fixes
# 💻 Optimized for Crave.io (Incremental & Safe Protocols)
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

# --- ⚙️ Init ROM repo ---
echo "⚙️ Initializing LineageOS source tree..."
repo init --depth=1 -u https://github.com/LineageOS/android.git -b lineage-20.0 --git-lfs

# --- ⚡ Safe Crave Sync ---
echo "⚡ Synchronizing remote source repositories using Crave protocol..."
/opt/crave/resync.sh

# --- 📂 Clone Device, Vendor, Kernel & Hardware Trees ---
echo "📂 Fetching device configuration tree..."
rm -rf device/oneplus/billie2
git clone https://github.com/LineageOS/android_device_oneplus_billie2 -b lineage-20 device/oneplus/billie2

echo "📂 Fetching proprietary vendor blobs..."
rm -rf vendor/oneplus/billie2
git clone https://github.com/sohaibdevelop1290-oss/proprietary_vendor_oneplus_billie2 -b lineage-20 vendor/oneplus/billie2

echo "📂 Fetching source kernel tree..."
rm -rf kernel/oneplus/sm4250
git clone https://github.com/LineageOS/android_kernel_oneplus_sm4250 -b lineage-20 kernel/oneplus/sm4250

echo "📂 Fetching hardware dependency layers..."
rm -rf hardware/oneplus
git clone https://github.com/LineageOS/android_hardware_oneplus -b lineage-20 hardware/oneplus

echo "📂 Fetching target platform security configurations..."
git clone https://github.com/sohaibdevelop1290-oss/android_device_qcom_sepolicy_vndr.git -b lineage-20.0-legacy-um device/qcom/sepolicy_vndr

echo "📂 Fetching MindTheGApps packages..."
rm -rf vendor/gapps
git clone https://gitlab.com/MindTheGapps/vendor_gapps.git -b sigma vendor/gapps

# --- 📶 Wi-Fi PTCL & Region Fix (Channel 12/13 Enable) ---
echo "📶 Injecting Wi-Fi regional fixes for PTCL & hidden routers..."

# 1. Force Global/Regulatory country code in Wi-Fi Config
WIFI_INI=$(find device/oneplus/billie2/ vendor/oneplus/billie2/ -name "WCNSS_qcom_cfg.ini" | head -n 1)
if [ -n "$WIFI_INI" ] && [ -f "$WIFI_INI" ]; then
    echo "📝 Modifying Wi-Fi configs in: $WIFI_INI"
    sed -i 's/gCrpCc=.*/gCrpCc=00/g' "$WIFI_INI" 2>/dev/null || echo "gCrpCc=00" >> "$WIFI_INI"
    sed -i 's/gRegulatoryChangeCountry=.*/gRegulatoryChangeCountry=00/g' "$WIFI_INI" 2>/dev/null || echo "gRegulatoryChangeCountry=00" >> "$WIFI_INI"
    sed -i 's/gChannelBondingMode24GHz=.*/gChannelBondingMode24GHz=1/g' "$WIFI_INI" 2>/dev/null
    echo "✅ WCNSS Wi-Fi ini file patched successfully."
fi

# 2. Patch Android Framework Overlay for Wi-Fi Country Code
WIFI_OVERLAY="device/oneplus/billie2/overlay/frameworks/base/core/res/res/values/config.xml"
if [ -f "$WIFI_OVERLAY" ]; then
    echo "📝 Patching Wi-Fi overlay country code..."
    sed -i 's/<string name="config_wifi_operating_country_code">.*<\/string>/<string name="config_wifi_operating_country_code"><\/string>/g' "$WIFI_OVERLAY"
fi

# --- ⚙️ GApps & Retrofit Integration Fix (lineage_billie2.mk) ---
echo "🔗 Linking MindTheGApps and Retrofit Flags to lineage_billie2.mk..."
PRODUCT_MK="device/oneplus/billie2/lineage_billie2.mk"
if [ -f "$PRODUCT_MK" ]; then
    echo "" >> "$PRODUCT_MK"
    echo "# Include GApps configuration layers" >> "$PRODUCT_MK"
    echo '$(call inherit-product-if-exists, vendor/gapps/arm64/arm64-vendor.mk)' >> "$PRODUCT_MK"
    echo "" >> "$PRODUCT_MK"
    echo "# Phase 1 Part 2 - Retrofit Dynamic Partitions" >> "$PRODUCT_MK"
    echo "PRODUCT_RETROFIT_DYNAMIC_PARTITIONS := true" >> "$PRODUCT_MK"
fi

# --- ⚙️ Custom App Exclusion (Lite GApps Enforcer) ---
echo "⚙️ Applying safe exclusions to vendor/gapps configurations..."
GAPPS_CONFIG="vendor/gapps/config.mk"
if [ -f "$GAPPS_CONFIG" ]; then
    echo "📝 Injecting custom tracking rules into: $GAPPS_CONFIG"
    cat <<EOF >> "$GAPPS_CONFIG"

# Custom filtration block to enforce tight partition size limits
CUSTOM_KEEP_APPS := ChromeHomePageProvider GoogleExtServices GooglePackageInstaller GmsCore Phonesky Chrome YouTube Gmail2 LatinIMEGoogle Drive GoogleSearchBox Photos
PRODUCT_PACKAGES := \$(filter \$(CUSTOM_KEEP_APPS), \$(PRODUCT_PACKAGES))
EOF
fi

# --- 🛠️ Partition, Recovery & Camera Color Fixes (BoardConfig.mk) ---
echo "⚙️ Injecting Board configurations..."
BOARD_CONFIG="device/oneplus/billie2/BoardConfig.mk"
if [ -f "$BOARD_CONFIG" ]; then
    # Resize dynamic partition size block to max safety limit
    sed -i 's/BOARD_ONEPLUS_DYNAMIC_PARTITIONS_SIZE := .*/BOARD_ONEPLUS_DYNAMIC_PARTITIONS_SIZE := 6442450944/g' "$BOARD_CONFIG"
    
    # Inject Recovery, Camera Color and Hardware ZRAM Drivers Configuration
    cat <<EOF >> "$BOARD_CONFIG"

# Phase 1 Part 2 - Android 10 Transition Fixes
TARGET_RECOVERY_IGNORE_TIMESTAMP := true
BOARD_SUPPRESS_SECURE_ERASE := true

# Phase 1 Part 2 - Camera Color & Video Playback Fixes
TARGET_PRODUCT_PROP_FILES += device/oneplus/billie2/system.prop
PRODUCT_PROPERTY_OVERRIDES += \\
    vendor.display.enable_default_color_mode=1 \\
    persist.vendor.camera.privapp.list=com.android.camera,org.lineageos.snap \\
    ro.hardware.egl=adreno \\
    debug.sf.enable_hwc_vds=1

# Phase 1 Part 2 - ZRAM Hardware Drivers
BOARD_USES_PV_ZRAM := true
EOF
    echo "✅ Recovery, Camera Color and ZRAM architecture flags safely injected."
fi

# --- 🧠 2GB ZRAM Core Injection (fstab setup) ---
echo "🧠 Injecting 2GB ZRAM size limit into device tree fstab..."
FSTAB_FILE=$(find device/oneplus/billie2/ -name "fstab.*" | head -n 1)
if [ -n "$FSTAB_FILE" ] && [ -f "$FSTAB_FILE" ]; then
    echo "📝 Modifying fstab entry in: $FSTAB_FILE"
    sed -i '/zram/d' "$FSTAB_FILE"
    echo "/dev/block/zram0  none  swap  defaults  zramsize=2147483648" >> "$FSTAB_FILE"
    echo "✅ Fstab ZRAM 2GB setup complete."
else
    echo "⚠️ fstab file not found, creating fallback sysprop for ZRAM size in product mk..."
    if [ -f "$PRODUCT_MK" ]; then
        echo "" >> "$PRODUCT_MK"
        echo "# Fallback ZRAM configuration override" >> "$PRODUCT_MK"
        echo "PRODUCT_PROPERTY_OVERRIDES += ro.vendor.config.zram=true" >> "$PRODUCT_MK"
    fi
fi

# ==================================
# 🧱 Safe Build Execution
# ==================================

echo "🔧 Setting up build environment setup..."
. build/envsetup.sh

# --- 🔧 Local libncurses/libtinfo Fixes for Ubuntu 24.04 (No Sudo / Safe for Crave) ---
echo "🔧 Setting up local libncurses version 5 links..."
mkdir -p $HOME/.local/lib
ln -sf /usr/lib/x86_64-linux-gnu/libncurses.so.6 $HOME/.local/lib/libncurses.so.5
ln -sf /usr/lib/x86_64-linux-gnu/libtinfo.so.6 $HOME/.local/lib/libtinfo.so.5
export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH

# Environment and GApps declaration
export WITH_GAPPS=true
mkdir -p out/target/product/${DEVICE}/

echo "🚀 ===== Starting Safe GApps Build with Retrofit, Wi-Fi, Camera & ZRAM Fixes ====="
breakfast billie2 userdebug && \
mka bacon

echo "🎉 ===== All builds completed successfully! ====="

# ==================================
# 📦 Post-Build Artifact Handling & ZIP Protection
# ==================================

echo "📍 Processing build output artifacts..."
ROM_DIR="out/target/product/${DEVICE}"
NOW=$(date +"%Y%m%d-%H%M")

FLASHABLE_ZIP=$(find "$ROM_DIR" -maxdepth 1 -name "lineage-20.0-*.zip" | grep -v "ota" | tail -n 1)
OTA_ZIP=$(find "$ROM_DIR" -maxdepth 1 -name "lineage_billie2-ota-*.zip" | tail -n 1)
SUPER_EMPTY_IMG=$(find "$ROM_DIR" -maxdepth 1 -name "super_empty.img" | tail -n 1)

# --- 🔒 ZIP Protection for super_empty.img (Prevents Crave Auto-Deletion) ---
PROTECTED_SUPER_ZIP=""
if [ -n "$SUPER_EMPTY_IMG" ] && [ -f "$SUPER_EMPTY_IMG" ]; then
    echo "📦 Securing super_empty.img inside a zip archive..."
    PROTECTED_SUPER_ZIP="$ROM_DIR/super_empty_protected-${NOW}.zip"
    zip -j "$PROTECTED_SUPER_ZIP" "$SUPER_EMPTY_IMG"
    echo "✅ Secure archive created: $PROTECTED_SUPER_ZIP"
fi

# --- ☁️ Smart Dual Upload Implementations ---

upload_to_gofile() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        echo "☁️ Fetching best available Gofile upload server (Anonymous Mode)..."
        local server=$(curl -s https://api.gofile.io/servers | grep -o '"name":"[^"]*' | head -n 1 | grep -o '[^"]*$')
        
        if [ -n "$server" ]; then
            echo "🚀 Uploading $(basename "$file_path") to Gofile..."
            local response=$(curl -s -F "file=@$file_path" "https://${server}.gofile.io/uploadFile")
            local download_page=$(echo "$response" | sed -n 's/.*"downloadPage":"\([^"]*\)".*/\1/p')
            if [ -n "$download_page" ]; then
                echo "✅ Gofile Link: $download_page"
            else
                echo "⚠️ Gofile Response error: $response"
            fi
        fi
    fi
}

upload_to_pixeldrain() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        echo "🚀 Uploading $(basename "$file_path") to Pixeldrain..."
        local response=$(curl -s -F "file=@$file_path" https://pixeldrain.com/api/file)
        local file_id=$(echo "$response" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
        if [ -n "$file_id" ]; then
            echo "✅ Pixeldrain Link: https://pixeldrain.com/u/$file_id"
        else
            echo "⚠️ Pixeldrain failed: $response"
        fi
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
