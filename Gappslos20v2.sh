#!/bin/bash

# ==================================
# 📱 LineageOS Build Script
# 🛠️ For: billie2 (Custom Tailored GApps List)
# 💻 Host System: Ubuntu 24.04 Compatibility
# ==================================

# Setup device variables early so clean-up paths work
export DEVICE="billie2"
export BUILD_USERNAME="sohaib"
export BUILD_HOSTNAME="crave"
export SKIP_ABI_CHECKS=true

# --- 🧹 Remove old local manifests ---
echo "🧹 Removing old manifests..."
rm -rf .repo/local_manifests
rm -rf .repo/manifests
rm -rf .repo/manifest.xml

# --- 🗑️ Remove Device Settings ---
echo "🗑️ Clearing legacy device configuration paths..."
rm -rf device/qcom/sepolicy_vndr

# --- ⚙️ Init ROM repo ---
echo "⚙️ Initializing LineageOS source tree..."
repo init --depth=1 -u https://github.com/LineageOS/android.git -b lineage-20.0 --git-lfs

# --- ⚡ Sync ROM ---
echo "⚡ Synchronizing remote source repositories..."
/opt/crave/resync.sh && \
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune

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
git clone https://gitlab.com/MindTheGapps/vendor_gapps.git -b arm64-20.0 vendor/gapps

# --- ⚙️ Safely Force Custom App Exclusion Overrides ---
echo "⚙️ Applying safe exclusions to vendor/gapps configurations..."
cat <<EOF >> vendor/gapps/config/gapps_packages.mk

# Custom filtration block to enforce your specific request list
CUSTOM_KEEP_APPS := ChromeHomePageProvider GoogleExtServices GooglePackageInstaller GmsCore Phonesky Chrome YouTube Gmail2 LatinIMEGoogle Drive GoogleSearchBox Photos
PRODUCT_PACKAGES := \$(filter \$(CUSTOM_KEEP_APPS), \$(PRODUCT_PACKAGES))
EOF

# ==================================
# 🧱 Build: billie2
# ==================================

# --- 🧹 Clean Target Device Output Folder ---
echo "🧹 Wiping old out/target/product/${DEVICE} folder to clear legacy build artifacts..."
rm -rf out/target/product/${DEVICE}

# --- 🔧 Build environment setup ---
echo "🔧 Injecting global system-wide libncurses/libtinfo fixes for Ubuntu 24.04..."
sudo ln -sf /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
sudo ln -sf /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5

# Force build framework to process our modified inline packages
export WITH_GAPPS=true

# --- 📁 Create Target Output Directory ---
echo "📁 Preparing local build output directories..."
mkdir -p out/target/product/${DEVICE}/

# --- 🚀 Build Execution ---
echo "🚀 ===== Starting Customized GApps Build ====="
. build/envsetup.sh && \
breakfast billie2 userdebug && \
make installclean && \
mka bacon

echo "🎉 ===== All builds completed successfully! ====="

# ==================================
# 📦 Post-Build Artifact Handling
# ==================================

echo "📍 Checking build output artifacts..."
ROM_DIR="out/target/product/${DEVICE}"

# Generate current date and timestamp strings (Format: YYYYMMDD-HHMM)
NOW=$(date +"%Y%m%d-%H%M")

# Find both distinct zip targets cleanly
FLASHABLE_ZIP=$(find "$ROM_DIR" -maxdepth 1 -name "lineage-20.0-*.zip" | grep -v "ota" | tail -n 1)
OTA_ZIP=$(find "$ROM_DIR" -maxdepth 1 -name "lineage_billie2-ota-*.zip" | tail -n 1)

# Rename and Verify Flashable ROM
if [ -n "$FLASHABLE_ZIP" ] && [ -f "$FLASHABLE_ZIP" ]; then
    NEW_FLASHABLE="${FLASHABLE_ZIP%.zip}-${NOW}.zip"
    mv "$FLASHABLE_ZIP" "$NEW_FLASHABLE"
    echo "📦 Flashable ROM stamped and ready at: $NEW_FLASHABLE"
else
    echo "⚠️ Target flashable ROM Zip file could not be found."
fi

# Rename and Verify OTA Update File
if [ -n "$OTA_ZIP" ] && [ -f "$OTA_ZIP" ]; then
    NEW_OTA="${OTA_ZIP%.zip}-${NOW}.zip"
    mv "$OTA_ZIP" "$NEW_OTA"
    echo "📦 OTA Update package stamped and ready at: $NEW_OTA"
else
    echo "⚠️ Target OTA Zip file could not be found."
fi

echo "🏁 Process finished!"
