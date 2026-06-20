#!/bin/bash

# ==================================
# LineageOS 22.1 (Android 15) Build Script
# For: billie2 (Vanilla - No GApps)
# Host System: Ubuntu 24.04 Compatibility
# ==================================

# --- Remove old local manifests ---
rm -rf .repo/local_manifests
rm -rf .repo/manifests
rm -rf .repo/manifest.xml

# --- Remove Device Settings --- (Reason: It will fail sync when we re-run this script)
rm -rf device/qcom/sepolicy_vndr

# --- Init ROM repo ---
repo init --depth=1 -u https://github.com/LineageOS/android.git -b lineage-22.1 --git-lfs

# --- Sync ROM ---
/opt/crave/resync.sh && \
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune

# --- Clone Device Tree ---
rm -rf device/oneplus/billie2
git clone https://github.com/LineageOS/android_device_oneplus_billie2 -b lineage-22.1 device/oneplus/billie2

# --- Clone Vendor Tree ---
rm -rf vendor/oneplus/billie2
git clone https://github.com/sohaibdevelop1290-oss/proprietary_vendor_oneplus_billie2 -b lineage-22.1 vendor/oneplus/billie2

# --- Clone Kernel Tree ---
rm -rf kernel/oneplus/sm4250
git clone https://github.com/LineageOS/android_kernel_oneplus_sm4250 -b lineage-22.1 kernel/oneplus/sm4250

# --- Clone Hardware Tree ---
rm -rf hardware/oneplus
git clone https://github.com/LineageOS/android_hardware_oneplus -b lineage-22.1 hardware/oneplus

# --- Clone Custom Sepolicy Tree (Updated to Custom Legacy Repository) ---
git clone https://github.com/sohaibdevelop1290-oss/android_device_qcom_sepolicy_vndr.git -b lineage-22.1-legacy-um device/qcom/sepolicy_vndr

# ==================================
# Build: billie2
# ==================================

# --- Build environment setup ---
echo "🔧 Setting up Ubuntu 24.04 library paths for Android 15 Toolchain..."

# Linux host libraries ko build path variables me save kar rahe hain taaki native libncurses.so.6 direct pick ho sake
export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"

# Setup device variables
export DEVICE="billie2"
export BUILD_USERNAME="sohaib"
export BUILD_HOSTNAME="crave"
export SKIP_ABI_CHECKS=true

# --- Create Target Output Directory ---
mkdir -p out/target/product/${DEVICE}/

# --- Vanilla Build Execution ---
echo "===== Starting LineageOS 22.1 Build ====="
. build/envsetup.sh && \
breakfast billie2 userdebug && \
make installclean && \
mka bacon

echo "===== All builds completed successfully! ====="
