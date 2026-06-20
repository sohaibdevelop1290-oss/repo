#!/bin/bash

# ==================================================================
# LineageOS 20.0 (Android 13) Optimized Cloud Build Script
# Target Device: OnePlus Nord N100 (codename: billie2)
# Host Compatibility: Ubuntu 24.04 (Headless Architecture)
# Platform: Crave.io Devspaces
# ==================================================================

# --- Exit Immediately If Any Step Fails Unexpectedly ---
set -e

# ==================================================================
# 1. ENVIRONMENT CONFIGURATION & WORKSPACE HOOKS
# ==================================================================
echo "🔧 Setting up environmental variables and workspace fixes..."

export DEVICE="billie2"
export BUILD_USERNAME="sohaib"
export BUILD_HOSTNAME="crave"
export SKIP_ABI_CHECKS=true

# Fix libncurses5/libtinfo5 dependency errors natively on Ubuntu 24.04 
# without calling 'sudo' (which causes headless cloud container freezes)
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/x86_64-linux-gnu

# Move directly into the source root directory inside Crave workspace environment
cd "/crave devspaces" 2>/dev/null || cd "$HOME/crave devspaces" 2>/dev/null || echo "ℹ️ Already at root directory or path handled by Crave wrapper."

# ==================================================================
# 2. PURGE OLD TRACKING MANIFESTS & CONFLICTING TREES
# ==================================================================
echo "🧹 Cleaning up existing workspace manifest definitions..."
rm -rf .repo/local_manifests
rm -rf .repo/manifests
rm -rf .repo/manifest.xml

echo "🗑️ Removing old source targets to prevent sync and compilation conflicts..."
rm -rf device/oneplus/${DEVICE}
rm -rf vendor/oneplus/${DEVICE}
rm -rf kernel/oneplus/sm4250
rm -rf hardware/oneplus
rm -rf device/qcom/sepolicy_vndr
rm -rf out/target/product/${DEVICE}

# ==================================================================
# 3. REPOSITORY INITIALIZATION & CLOUD RESYNC
# ==================================================================
echo "🔄 Initializing LineageOS 20.0 Source Tree via Git-LFS..."
repo init --depth=1 -u https://github.com/LineageOS/android.git -b lineage-20.0 --git-lfs

echo "⚡ Executing parallel source sync utilizing Crave's infrastructure infrastructure..."
/opt/crave/resync.sh

# ==================================================================
# 4. CLONING DEVICE SPECIFIC TREES (LineageOS 20 Branches)
# ==================================================================
echo "📂 Cloning device trees for ${DEVICE}..."
git clone https://github.com/LineageOS/android_device_oneplus_billie2 -b lineage-20 device/oneplus/billie2

echo "📂 Cloning proprietary vendor blobs..."
git clone https://github.com/sohaibdevelop1290-oss/proprietary_vendor_oneplus_billie2 -b lineage-20 vendor/oneplus/billie2

echo "📂 Cloning Snapdragon 460 Kernel Tree..."
git clone https://github.com/LineageOS/android_kernel_oneplus_sm4250 -b lineage-20 kernel/oneplus/sm4250

echo "📂 Cloning unified hardware dependencies..."
git clone https://github.com/LineageOS/android_hardware_oneplus -b lineage-20 hardware/oneplus

echo "📂 Injecting compatible legacy Qualcomm Sepolicy Vendor configurations..."
git clone https://github.com/sohaibdevelop1290-oss/android_device_qcom_sepolicy_vndr.git -b lineage-20.0-legacy-um device/qcom/sepolicy_vndr

# ==================================================================
# 5. COMPILATION LAYER EXECUTION (Vanilla Build)
# ==================================================================
echo "📁 Setting up clean target output layout folder..."
mkdir -p out/target/product/${DEVICE}

echo "🚀 Loading Android Build Environment Hooks..."
. build/envsetup.sh

echo "🥣 Executing Breakfast command layer for ${DEVICE}..."
breakfast ${DEVICE} userdebug

echo "🧼 Clearing intermediate object files via installclean..."
make installclean

echo "🧱 Starting the primary compilation engine (mka bacon)..."
mka bacon

echo "=================================================================="
echo "🎉 SUCCESS: LineageOS 20.0 build process finished successfully!"
echo "📦 Your flashable target ZIP file is located inside:"
echo "   out/target/product/${DEVICE}/"
echo "=================================================================="
