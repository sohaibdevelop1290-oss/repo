#!/bin/bash

# ==================================
# 📱 LineageOS Build Script
# 🛠️ For: billie2 (Vanilla - No GApps)
# 💻 Host System: Ubuntu 24.04 Compatibility
# ==================================

# --- 🧹 Remove old local manifests ---
echo "🧹 Removing old manifests..."
rm -rf .repo/local_manifests
rm -rf .repo/manifests
rm -rf .repo/manifest.xml

# --- 🗑️ Remove Device Settings --- (Reason: It will fail sync when we re-run this script)
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

# --- 📂 Clone Custom Sepolicy Tree (Updated with compatible legacy repo) ---
echo "📂 Fetching target platform security configurations..."
git clone https://github.com/sohaibdevelop1290-oss/android_device_qcom_sepolicy_vndr.git -b lineage-20.0-legacy-um device/qcom/sepolicy_vndr

# ==================================
# 🧱 Build: billie2
# ==================================

# --- 🧹 Clean Target Device Output Folder ---
echo "🧹 Wiping old out/target/product/${DEVICE} folder to clear legacy build artifacts..."
rm -rf out/target/product/${DEVICE}

# --- 🔧 Build environment setup ---
echo "🔧 Injecting global system-wide libncurses/libtinfo fixes for Ubuntu 24.04..."

# System-wide global fix so all host tools (clang, bcc_strip_attr, etc.) don't fail
sudo ln -sf /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
sudo ln -sf /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5

# Setup device variables
export DEVICE="billie2"
export BUILD_USERNAME="sohaib"
export BUILD_HOSTNAME="crave"
export SKIP_ABI_CHECKS=true

# --- 📁 Create Target Output Directory ---
echo "📁 Preparing local build output directories..."
mkdir -p out/target/product/${DEVICE}/

# --- 🚀 Vanilla Build Execution ---
echo "🚀 ===== Starting Vanilla Build ====="
. build/envsetup.sh && \
breakfast billie2 userdebug && \
make installclean && \
mka bacon

echo "🎉 ===== All builds completed successfully! ====="

# ==================================
# 📦 Post-Build Artifact Handling
# ==================================

# --- 📍 Final location check & Safe Relocation ---
echo "📍 Checking build output artifacts..."
ROM_DIR="out/target/product/${DEVICE}"
ZIP_FILE=$(ls "$ROM_DIR" 2>/dev/null | grep -E "^lineage-.*\.zip$" | tail -n 1)

if [ -n "$ZIP_FILE" ]; then
    echo "📦 Output ROM Zip Location: ${ROM_DIR}/${ZIP_FILE}"
    echo "🚚 Relocating flashable zip safely..."
    
    # Check if rave-devspaces exists as a relative path folder in the current workspace
    if [ -d "crave-devspaces" ]; then
        mv "${ROM_DIR}/${ZIP_FILE}" ./crave-devspaces/
        echo "📥 Successfully moved zip to ./crave-devspaces/"
    else
        mv "${ROM_DIR}/${ZIP_FILE}" ./
        echo "📥 Moved zip to project root directory (./) because crave-devspaces directory was not found matching locally."
    fi
else
    echo "⚠️ Target ROM Zip file could not be found locally."
fi

echo "🏁 Process finished!"
