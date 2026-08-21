#!/bin/bash

# =====================================================================
# 📱 matrixx (Android 15 - Fifteen) Production Script
# =====================================================================
# ⚙️ Target Device: OnePlus Nord N100 (billie2)
# 🔄 Base Source: matrixx Source (Lineage 22.2 Architecture)
# 💻 Environment: Cloud Optimized for Crave.io Workspace (No Clean)
# 👤 Maintainer: Sohaib
# =====================================================================

# ---------------------------------------------------------------------
# 1. ENVIRONMENT CONFIGURATION & GLOBAL VARIABLES
# ---------------------------------------------------------------------
echo "⚙️ Setting up matrixx Android 15 environment parameters..."
export DEVICE="billie2"
export SKIP_ABI_CHECKS=true

# Force UTF-8 encoding for terminal compatibility
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Pre-create the output directory structure
mkdir -p out/target/product/${DEVICE}/
# ---------------------------------------------------------------------
# 2. PRE-SYNC WORKSPACE PURGE & CLEANUP
# ---------------------------------------------------------------------
echo "🧹 Safely removing old zip and image artifacts..."
rm -rf out/target/product/${DEVICE}/*.zip
rm -rf out/target/product/${DEVICE}/*.img
rm -rf .repo/local_manifests .repo/manifests .repo/manifest.xml

echo "🔥 Purging older device trees to prevent git conflicts..."
rm -rf device/oneplus/billie2
rm -rf vendor/oneplus/billie2
rm -rf kernel/oneplus/sm4250
rm -rf hardware/oneplus
# ---------------------------------------------------------------------
# 3. matrixx15qpr2 SOURCE INITIALIZATION & SYNCHRONIZATION
# ---------------------------------------------------------------------
echo "⚙️ Initializing upstream matrixx15qpr2 Android 15 (Fifteen) manifest..."
repo init -u https://github.com/ProjectMatrixx/android.git -b 15.0 --git-lfs

echo "⚡ Executing dual-sync mechanism (Crave Fabric + Manual Backup)..."
/opt/crave/resync.sh

echo "🔄 Running requested repo sync command..."
repo sync -c --no-clone-bundle --optimized-fetch --prune --force-sync -j$(nproc --all)

# ---------------------------------------------------------------------
# 4. FETCHING CUSTOM PRODUCTION TREES
# ---------------------------------------------------------------------
echo "📂 Cloning LineageOS 22.2 based device tree with matrixx15qpr2 branch..."
git clone https://github.com/sohaibdevelop1290-oss/android_device_oneplus_billie2.git -b matrixx15qpr2 device/oneplus/billie2

echo "📂 Cloning vendor blobs (Lineage 22.2) repository..."
git clone https://github.com/sohaibdevelop1290-oss/proprietary_vendor_oneplus_billie2 -b lineage-22.2 vendor/oneplus/billie2

echo "📂 Cloning Linux kernel 4.19 architecture tree..."
git clone https://github.com/LineageOS/android_kernel_oneplus_sm4250 -b lineage-22.2 kernel/oneplus/sm4250

echo "📂 Cloning hardware implementation layers..."
git clone https://github.com/LineageOS
