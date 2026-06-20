#!/bin/bash

# ==================================
# LineageOS Build Script
# For: billie2
# ==================================

# --- Remove old local manifests ---
rm -rf .repo/local_manifests
rm -rf .repo/manifests
rm -rf .repo/manifest.xml

# --- Remove Device Settings --- (Reason: It will fail sync when we re-run this script)
rm -rf device/qcom/sepolicy_vndr

# --- Init ROM repo ---
repo init --depth=1 -u https://github.com/LineageOS/android.git -b lineage-20.0 --git-lfs

# --- Sync ROM ---
/opt/crave/resync.sh && \
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune

# --- Clone Device Tree ---
rm -rf device/oneplus/billie2
git clone https://github.com/LineageOS/android_device_oneplus_billie2 -b lineage-20 device/oneplus/billie2

# --- Clone Vendor Tree ---
rm -rf vendor/oneplus/billie2
git clone https://github.com/sohaibdevelop1290-oss/proprietary_vendor_oneplus_billie2 -b lineage-20 vendor/oneplus/billie2

# --- Clone Kernel Tree ---
rm -rf kernel/oneplus/sm4250
git clone https://github.com/LineageOS/android_kernel_oneplus_sm4250 -b lineage-20 kernel/oneplus/sm4250

# --- Clone Hardware Tree ---
rm -rf hardware/oneplus
git clone https://github.com/LineageOS/android_hardware_oneplus -b lineage-20 hardware/oneplus

# --- Clone Custom Sepolicy Tree ---
git clone https://github.com/LineageOS/android_device_qcom_sepolicy_vndr -b lineage-20.0-legacy-um device/qcom/sepolicy_vndr

# ==================================
# Build: billie2
# ==================================

# --- Build environment setup ---
echo "🔧 Fixing environment dependencies..."
sudo apt-get update && sudo apt-get install -y libncurses5

export BUILD_USERNAME="sohaib"
export BUILD_HOSTNAME="crave"
export SKIP_ABI_CHECKS=true

# --- Vanilla Build ---
echo "===== Starting Vanilla Build ====="
. build/envsetup.sh && \
breakfast billie2 userdebug && \
make installclean && \
mka bacon

echo "===== All builds completed successfully! ====="
