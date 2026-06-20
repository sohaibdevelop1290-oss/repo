#!/bin/bash

# set pipelined command flow
set -o pipefail

# Define variables for billie2
DEVICE="billie2"
ROM_NAME="lineage"
ROM_VERSION="20.0"

BUILD_LOG="build.log"
OUT_DIR="out/target/product/${DEVICE}"
START_TIME=$(date +%s)

# ================= TIMEZONE =================
if [ -n "$TZ" ]; then
    sudo rm -f /etc/localtime
    sudo ln -s /usr/share/zoneinfo/${TZ} /etc/localtime
fi

echo "🚀 ${DEVICE} Build started"

# Automatic cleanup of device folders before syncing
echo "Performing safe compilation cleanup..."
remove=(
    .repo/local_manifests
    device/oneplus
    kernel/oneplus
    vendor/oneplus
    hardware/oneplus
    device/qcom/sepolicy_vndr
)

for folder in "${remove[@]}"; do
    rm -rf "$folder"
    echo "    Cleaned: $folder"
done

# Initialize the ROM source repository
repo init -u https://github.com/LineageOS/android.git -b lineage-20.0 --git-lfs
if [ $? -ne 0 ]; then
    echo "Repo initialization failed. Exiting."
    exit 1
fi
echo ""

# Reset entire master source tree if it exists
if [ -d ".repo/project-objects" ]; then
    echo "Discarding edits from main source tree..."
    repo forall -c 'git reset --hard HEAD --quiet'
    repo forall -c 'git clean -fdx --quiet'
    echo "Main source tree is now clean."
fi

# Sync the repositories using the Crave sync script followed by manual sync
/opt/crave/resync.sh && \
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune
if [ $? -ne 0 ]; then
    echo "Crave sync or manual repo sync failed. Exiting."
    exit 1
fi

# Clone Device Trees manually
echo "Cloning target hardware repositories..."
git clone https://github.com/LineageOS/android_device_oneplus_billie2 -b lineage-20 device/oneplus/billie2 && \
git clone https://github.com/sohaibdevelop1290-oss/proprietary_vendor_oneplus_billie2 -b lineage-20 vendor/oneplus/billie2 && \
git clone https://github.com/LineageOS/android_kernel_oneplus_sm4250 -b lineage-20 kernel/oneplus/sm4250 && \
git clone https://github.com/LineageOS/android_hardware_oneplus -b lineage-20 hardware/oneplus && \
git clone https://github.com/LineageOS/android_device_qcom_sepolicy_vndr -b lineage-20.0-legacy-um device/qcom/sepolicy_vndr

if [ $? -ne 0 ]; then
    echo "Tree cloning failed. Exiting."
    exit 1
fi

# Build environment setup
source build/envsetup.sh
export BUILD_USERNAME="sohaib"
export BUILD_HOSTNAME="crave"
export SKIP_ABI_CHECKS=true

# Build the ROM
breakfast ${DEVICE} userdebug
if [ $? -ne 0 ]; then
    echo "Breakfast failed. Exiting."
    exit 1
fi

make installclean
if [ $? -ne 0 ]; then
    echo "Installclean failed. Exiting."
    exit 1
fi

mka bacon 2>&1 | tee "$BUILD_LOG"

END_TIME=$(date +%s)
BUILD_DIFF=$((END_TIME - START_TIME))
if [ $BUILD_DIFF -ge 3600 ]; then
    BUILD_TIME="$((BUILD_DIFF/3600))h $(((BUILD_DIFF%3600)/60))min"
else
    BUILD_TIME="$((BUILD_DIFF/60)) min"
fi

# ================= ON FAIL / SUCCESS =================
if grep -q -E "ninja failed|failed to build some targets" "$BUILD_LOG"; then
    echo "💥 Build failed! Took ${BUILD_TIME}"
else
    echo "✅ Build completed successfully!"
    echo "⏱️ Total Time Taken: ${BUILD_TIME}"
    
    # Final location check
    ROM_DIR="out/target/product/${DEVICE}"
    ZIP_FILE=$(ls "$ROM_DIR" 2>/dev/null | grep -E "^lineage-.*\.zip$" | tail -n 1)
    if [ -n "$ZIP_FILE" ]; then
        echo "📦 Output ROM Zip: ${ROM_DIR}/${ZIP_FILE}"
    fi
fi

echo "
.....Script completed!....."
