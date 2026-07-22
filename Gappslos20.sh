#!/bin/bash

# =====================================================================
# 📱 LineageOS Optimized Build Script - HARDWARE & RECOVERY FIX EDITION
# =====================================================================
# ⚙️ Target Device: OnePlus Nord N100 (billie2)
# 🔒 Build Phase: Android 13 (LineageOS 20.0) Stable Phase
# 💻 Environment: Cloud Optimized for Crave.io Workspace
# 👤 Maintainer: Sohaib
# =====================================================================

# ---------------------------------------------------------------------
# 1. ENVIRONMENT CONFIGURATION & GLOBAL VARIABLES
# ---------------------------------------------------------------------
echo "⚙️ Configuring build environment parameters..."
export DEVICE="billie2"
export BUILD_USERNAME="sohaib"
export BUILD_HOSTNAME="crave"
export SKIP_ABI_CHECKS=true
export WITH_GAPPS=true

# Force UTF-8 Terminal Encoding to prevent broken characters
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Create output structure preemptively
mkdir -p out/target/product/${DEVICE}/

# ---------------------------------------------------------------------
# 2. PRE-SYNC WORKSPACE PURGE & CLEANUP
# ---------------------------------------------------------------------
echo "🧹 Safely purging active target directory artifacts to secure disk space..."
rm -rf out/target/product/${DEVICE}/*.zip
rm -rf out/target/product/${DEVICE}/*.img

echo "🧹 Clearing legacy manifest files and lock mechanisms..."
rm -rf .repo/local_manifests
rm -rf .repo/manifests
rm -rf .repo/manifest.xml

echo "🗑️ Dropping legacy target security policy definitions..."
rm -rf device/qcom/sepolicy-legacy-um

echo "🔥 [CRUCIAL] Clearing target repository source trees to block Git checkout failures..."
rm -rf device/oneplus/billie2
rm -rf vendor/oneplus/billie2
rm -rf kernel/oneplus/sm4250
rm -rf hardware/oneplus

# ---------------------------------------------------------------------
# 3. SOURCE TREE INITIALIZATION & MANIFEST SYNCHRONIZATION
# ---------------------------------------------------------------------
echo "⚙️ Initializing upstream LineageOS Android platform source tree..."
repo init --depth=1 -u https://github.com/LineageOS/android.git -b lineage-20.0 --git-lfs

echo "⚡ Executing high-speed safe workspace synchronization via Crave fabric..."
/opt/crave/resync.sh

# ---------------------------------------------------------------------
# 4. REMOTE TREES CLONING & DEPENDENCY MANAGEMENT
# ---------------------------------------------------------------------
echo "📂 Fetching device tree configuration..."
git clone https://github.com/LineageOS/android_device_oneplus_billie2 -b Glineage-20 device/oneplus/billie2

echo "📂 Fetching proprietary vendor blob repositories..."
git clone https://github.com/sohaibdevelop1290-oss/proprietary_vendor_oneplus_billie2 -b lineage-20 vendor/oneplus/billie2

echo "📂 Fetching target platform Linux kernel architecture tree..."
git clone https://github.com/LineageOS/android_kernel_oneplus_sm4250 -b lineage-20 kernel/oneplus/sm4250

echo "📂 Fetching vendor hardware implementation layers..."
git clone https://github.com/LineageOS/android_hardware_oneplus -b lineage-20 hardware/oneplus

echo "📂 Fetching structural MindTheGApps core packages..."
rm -rf vendor/gapps
git clone https://gitlab.com/MindTheGapps/vendor_gapps.git -b sigma vendor/gapps

# ---------------------------------------------------------------------
# 6. GAPPS ARCHITECTURE LINKING & LITE APP FILTERING
# ---------------------------------------------------------------------
echo "🔗 Structuring MindTheGApps linkage inside product design maps..."
PRODUCT_MK="device/oneplus/billie2/lineage_billie2.mk"
if [ -f "$PRODUCT_MK" ]; then
    echo -e "\n# Include GApps configuration layers\n\$(call inherit-product-if-exists, vendor/gapps/arm64/arm64-vendor.mk)" >> "$PRODUCT_MK"
fi

GAPPS_CONFIG="vendor/gapps/config.mk"
if [ -f "$GAPPS_CONFIG" ]; then
    cat <<EOF >> "$GAPPS_CONFIG"
CUSTOM_KEEP_APPS := ChromeHomePageProvider GoogleExtServices GooglePackageInstaller GmsCore Phonesky Chrome YouTube Gmail2 LatinIMEGoogle Drive GoogleSearchBox Photos
PRODUCT_PACKAGES := \$(filter \$(CUSTOM_KEEP_APPS), \$(PRODUCT_PACKAGES))
EOF
fi

# ---------------------------------------------------------------------
# 8. COMPILATION INITIATION & DEEP TARGET IMAGE ARREST
# ---------------------------------------------------------------------
echo "🔧 Setting up cross-compilation toolchain and environment variables..."
. build/envsetup.sh

# Fixing modern Ubuntu legacy dependency missing issues seamlessly
mkdir -p $HOME/.local/lib
ln -sf /usr/lib/x86_64-linux-gnu/libncurses.so.6 $HOME/.local/lib/libncurses.so.5
ln -sf /usr/lib/x86_64-linux-gnu/libtinfo.so.6 $HOME/.local/lib/libtinfo.so.5
export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH

echo "🚀 Starting full target production build (mka bacon)..."
breakfast billie2 userdebug && mka bacon

# =====================================================================
# 🛠️ FIXED UPLOAD SECTION (UPLOADS ZIP FILES & SUPER_EMPTY IMAGE)
# =====================================================================
echo "📍 Finding and capturing flashable ZIP artifacts and super_empty.img..."

# آؤٹ پٹ فولڈر کا پاتھ سیٹ کرنا
OUT_DIR="out/target/product/${DEVICE}"

# پروفیشنل گو فائل اپلوڈر فنکشن
upload_to_gofile() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        echo "📤 Uploading $(basename "$file_path") to GoFile..."
        local server=$(curl -s https://api.gofile.io/servers | grep -o '"name":"[^"]*' | head -n 1 | grep -o '[^"]*$')
        if [ -n "$server" ]; then
            local response=$(curl -s -F "file=@$file_path" "https://${server}.gofile.io/uploadFile")
            local download_page=$(echo "$response" | sed -n 's/.*"downloadPage":"\([^"]*\)".*/\1/p')
            if [ -n "$download_page" ]; then
                echo "🌐 [GOFILE LINK]: $download_page"
            else
                echo "❌ Upload failed or response was empty for $(basename "$file_path")."
            fi
        else
            echo "❌ GoFile API server list could not be retrieved."
        fi
    else
        echo "⚠️ Warning: File not found at $file_path"
    fi
}

if [ -d "$OUT_DIR" ]; then
    # 1. تمام زپ فائلز تلاش اور اپلوڈ کرنا
    ZIPS=($(find "$OUT_DIR" -maxdepth 1 -name "*.zip" | grep -v "super_empty"))
    
    if [ ${#ZIPS[@]} -gt 0 ]; then
        echo "📦 Found ${#ZIPS[@]} ZIP file(s). Initiating upload..."
        for zip_file in "${ZIPS[@]}"; do
            upload_to_gofile "$zip_file"
        done
    else
        echo "❌ No ZIP files found in $OUT_DIR to upload."
    fi

    # 2. super_empty.img کو تلاش کرنا اور ڈائریکٹ اپلوڈ کرنا
    echo "🔍 Searching for super_empty.img..."
    SUPER_EMPTY=$(find "$OUT_DIR" -name "super_empty.img" | head -n 1)
    
    if [ -n "$SUPER_EMPTY" ] && [ -f "$SUPER_EMPTY" ]; then
        echo "📦 Found super_empty.img at: $SUPER_EMPTY"
        upload_to_gofile "$SUPER_EMPTY"
    else
        echo "⚠️ Warning: super_empty.img could not be located anywhere in $OUT_DIR"
    fi
else
    echo "❌ Target output directory $OUT_DIR does not exist."
fi

echo "🏁 [SUCCESS] Full build execution lifecycle finalized cleanly!"
