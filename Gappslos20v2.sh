#!/bin/bash

# ==================================
# 📱 LineageOS Safe Build Script
# 🛠️ For: billie2 (Custom GApps + Dual Cloud Uploads)
# 💻 Host System: Ubuntu 24.04 Compatibility
# 🔒 Optimized for Crave.io (Incremental Build - No Clean)
# ==================================

# Setup device variables early
export DEVICE="billie2"
export BUILD_USERNAME="sohaib"
export BUILD_HOSTNAME="crave"
export SKIP_ABI_CHECKS=true

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

# --- 📂 Clone Device Tree ---
echo "📂 Fetching device configuration tree..."
rm -rf device/oneplus/billie2
git clone https://github.com/LineageOS/android_device_oneplus_billie2 -b lineage-20 device/oneplus/billie2

# --- 📂 Clone Vendor Tree ---
echo "📂 Fetching proprietary vendor blobs..."
rm -rf vendor/oneplus/billie2
git clone https://github.com/sohaibdevelop1290-oss/proprietary_vendor_oneplus_billie2 -b lineage-20 vendor/oneplus/billie2

# --- 📂 Clone Kernel Tree ---
echo "📂 Fetching source kernel tree..."
rm -rf kernel/oneplus/sm4250
git clone https://github.com/LineageOS/android_kernel_oneplus_sm4250 -b lineage-20 kernel/oneplus/sm4250

# --- 📂 Clone Hardware Tree ---
echo "📂 Fetching hardware dependency layers..."
rm -rf hardware/oneplus
git clone https://github.com/LineageOS/android_hardware_oneplus -b lineage-20 hardware/oneplus

# --- 📂 Clone Custom Sepolicy Tree ---
echo "📂 Fetching target platform security configurations..."
git clone https://github.com/sohaibdevelop1290-oss/android_device_qcom_sepolicy_vndr.git -b lineage-20.0-legacy-um device/qcom/sepolicy_vndr

# --- 📂 Clone MindTheGApps Tree ---
echo "📂 Fetching MindTheGApps implementation packages..."
rm -rf vendor/gapps
git clone https://gitlab.com/MindTheGapps/vendor_gapps.git -b sigma vendor/gapps

# --- ⚙️ GApps Integration Fix ---
echo "🔗 Linking MindTheGApps to lineage_billie2.mk..."
PRODUCT_MK="device/oneplus/billie2/lineage_billie2.mk"
if [ -f "$PRODUCT_MK" ]; then
    echo "" >> "$PRODUCT_MK"
    echo "# Include GApps configuration layers" >> "$PRODUCT_MK"
    echo '$(call inherit-product-if-exists, vendor/gapps/arm64/arm64-vendor.mk)' >> "$PRODUCT_MK"
fi

# --- ⚙️ Custom App Exclusion Injection ---
echo "⚙️ Applying safe exclusions to vendor/gapps configurations..."
GAPPS_CONFIG="vendor/gapps/config.mk"

if [ -f "$GAPPS_CONFIG" ]; then
    echo "📝 Injecting custom tracking rules into: $GAPPS_CONFIG"
    cat <<EOF >> "$GAPPS_CONFIG"

# Custom filtration block to enforce specific request list
CUSTOM_KEEP_APPS := ChromeHomePageProvider GoogleExtServices GooglePackageInstaller GmsCore Phonesky Chrome YouTube Gmail2 LatinIMEGoogle Drive GoogleSearchBox Photos
PRODUCT_PACKAGES := \$(filter \$(CUSTOM_KEEP_APPS), \$(PRODUCT_PACKAGES))
EOF
else
    echo "⚠️ Warning: $GAPPS_CONFIG target file was not found to inject overrides."
fi

# --- 🚀 Dynamic Partition Capacity Adjustment ---
echo "⚙️ Expanding device dynamic partitions limit to prevent size failures..."
BOARD_CONFIG="device/oneplus/billie2/BoardConfig.mk"
if [ -f "$BOARD_CONFIG" ]; then
    sed -i 's/BOARD_ONEPLUS_DYNAMIC_PARTITIONS_SIZE := .*/BOARD_ONEPLUS_DYNAMIC_PARTITIONS_SIZE := 6442450944/g' "$BOARD_CONFIG"
    echo "✅ Dynamic partition group threshold safely updated to 6GB inside BoardConfig.mk"
else
    echo "⚠️ Target BoardConfig.mk file was not found to inject partition resize modifications."
fi

# ==================================
# 🧱 Safe Build Execution (No Clean/No Clobber)
# ==================================

echo "🔧 Setting up build environment setup..."
. build/envsetup.sh

# ONLY clearing the specific old zip and img files to avoid full cache wiping
echo "🧹 Safely clearing old flashable target artifacts..."
rm -rf out/target/product/${DEVICE}/*.zip
rm -rf out/target/product/${DEVICE}/*.img

echo "🔧 Injecting global system-wide libncurses/libtinfo fixes for Ubuntu 24.04..."
sudo ln -sf /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
sudo ln -sf /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5

export WITH_GAPPS=true
mkdir -p out/target/product/${DEVICE}/

echo "🚀 ===== Starting Safe Incremental GApps Build ====="
breakfast billie2 userdebug && \
make installclean && \
mka bacon

echo "🎉 ===== All builds completed successfully! ====="

# ==================================
# 📦 Post-Build Artifact Handling & Upload
# ==================================

echo "📍 Checking build output artifacts..."
ROM_DIR="out/target/product/${DEVICE}"
NOW=$(date +"%Y%m%d-%H%M")

FLASHABLE_ZIP=$(find "$ROM_DIR" -maxdepth 1 -name "lineage-20.0-*.zip" | grep -v "ota" | tail -n 1)
OTA_ZIP=$(find "$ROM_DIR" -maxdepth 1 -name "lineage_billie2-ota-*.zip" | tail -n 1)

upload_to_gofile() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        if [ -z "$GOFILE_TOKEN" ]; then
            echo "⚠️ Skipping Gofile upload: GOFILE_TOKEN is empty."
            return
        fi

        echo "☁️ Fetching best available Gofile upload server..."
        local server=$(curl -s https://api.gofile.io/servers | grep -o '"name":"[^"]*' | head -n 1 | grep -o '[^"]*$')
        
        if [ -n "$server" ]; then
            echo "🚀 Uploading $(basename "$file_path") to Gofile..."
            local response=$(curl -s -H "Authorization: Bearer $GOFILE_TOKEN" -F "file=@$file_path" "https://${server}.gofile.io/uploadFile")
            local download_page=$(echo "$response" | sed -n 's/.*"downloadPage":"\([^"]*\)".*/\1/p')
            if [ -n "$download_page" ]; then
                echo "✅ Gofile Upload Successful!"
                echo "🔗 Gofile Link: $download_page"
            else
                echo "⚠️ Gofile failed to parse link. Response: $response"
            fi
        else
            echo "⚠️ Could not retrieve active Gofile server node."
        fi
    fi
}

upload_to_pixeldrain() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        echo "🚀 Uploading $(basename "$file_path") to Pixeldrain..."
        
        local response
        if [ -n "$PIXELDRAIN_TOKEN" ]; then
            response=$(curl -s -u ":$PIXELDRAIN_TOKEN" -F "file=@$file_path" https://pixeldrain.com/api/file)
        else
            echo "⚠️ PIXELDRAIN_TOKEN is empty. Dropping to anonymous upload..."
            response=$(curl -s -F "file=@$file_path" https://pixeldrain.com/api/file)
        fi
        
        local file_id=$(echo "$response" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
        if [ -n "$file_id" ]; then
            echo "✅ Pixeldrain Upload Successful!"
            echo "🔗 Pixeldrain Link: https://pixeldrain.com/u/$file_id"
        else
            echo "⚠️ Pixeldrain failed. Response: $response"
        fi
    fi
}

if [ -n "$FLASHABLE_ZIP" ] && [ -f "$FLASHABLE_ZIP" ]; then
    NEW_FLASHABLE="${FLASHABLE_ZIP%.zip}-${NOW}.zip"
    mv "$FLASHABLE_ZIP" "$NEW_FLASHABLE"
    echo "📦 Flashable ROM ready at: $NEW_FLASHABLE"
    upload_to_gofile "$NEW_FLASHABLE"
    upload_to_pixeldrain "$NEW_FLASHABLE"
else
    echo "⚠️ Flashable ROM Zip file could not be found."
fi

if [ -n "$OTA_ZIP" ] && [ -f "$OTA_ZIP" ]; then
    NEW_OTA="${OTA_ZIP%.zip}-${NOW
    
