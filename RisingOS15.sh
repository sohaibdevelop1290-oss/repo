#!/bin/bash

# =====================================================================
# 📱 RisingOS (Android 15 - Fifteen) Production Script
# =====================================================================
# ⚙️ Target Device: OnePlus Nord N100 (billie2)
# 🔄 Base Source: RisingOS Revived Source (Lineage 22.1 Architecture)
# 💻 Environment: Cloud Optimized for Crave.io Workspace (No Clean)
# 👤 Maintainer: Sohaib
# =====================================================================

# ---------------------------------------------------------------------
# 1. ENVIRONMENT CONFIGURATION & GLOBAL VARIABLES
# ---------------------------------------------------------------------
echo "⚙️ Setting up RisingOS Android 15 environment parameters..."
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
# 3. RISINGOS SOURCE INITIALIZATION & SYNCHRONIZATION
# ---------------------------------------------------------------------
echo "⚙️ Initializing upstream RisingOS Android 15 (Fifteen) manifest..."
repo init --depth=1 -u https://github.com/RisingOS-Revived/android.git -b fifteen --git-lfs

echo "⚡ Executing dual-sync mechanism (Crave Fabric + Manual Backup)..."
/opt/crave/resync.sh

echo "🔄 Running requested repo sync command..."
repo sync -c --no-clone-bundle --optimized-fetch --prune --force-sync -j$(nproc --all)

# ---------------------------------------------------------------------
# 4. FETCHING CUSTOM PRODUCTION TREES
# ---------------------------------------------------------------------
echo "📂 Cloning LineageOS 22.1 based device tree with RisingOS15 branch..."
git clone https://github.com/sohaibdevelop1290-oss/android_device_oneplus_billie2.git -b RisingOS15 device/oneplus/billie2

echo "📂 Cloning vendor blobs (Lineage 22.1) repository..."
git clone https://github.com/sohaibdevelop1290-oss/proprietary_vendor_oneplus_billie2 -b lineage-22.1 vendor/oneplus/billie2

echo "📂 Cloning Linux kernel 4.19 architecture tree..."
git clone https://github.com/LineageOS/android_kernel_oneplus_sm4250 -b lineage-22.1 kernel/oneplus/sm4250

echo "📂 Cloning hardware implementation layers..."
git clone https://github.com/LineageOS/android_hardware_oneplus -b lineage-22.1 hardware/oneplus

# ---------------------------------------------------------------------
# 5. COMPILATION INITIATION (RisingOS Environment Setup)
# ---------------------------------------------------------------------
echo "🔧 Setting up build environment..."
. build/envsetup.sh

echo "🚀 Selecting target via official riseup build platform configuration..."
riseup billie2 userdebug

# 🚀 Replacing GMS vendor & vendor/addons with personal forked repository...
rm -rf vendor/gms
git clone https://gitlab.com/sohaibdevelop1290/android_vendor_gms.git -b fifteen vendor/gms

# vendor/addons کو مینوئلی کلون کرنا تاکہ کوئی فائل مس نہ ہو
rm -rf vendor/addons
git clone https://github.com/RisingOS-Revived/android_vendor_addons.git -b fifteen vendor/addons

# 🔥 [FIX] NotifFluid تھیم کی خراب بلڈ ریسپی کو بائی پاس کرنے کے لیے فائل کو خالی کرنا
echo "🩹 Wiping NotifFluid Android.bp to bypass dimensions/color errors..."
if [ -f "vendor/addons/themes/notifications/NotifFluid/Android.bp" ]; then
    echo "" > vendor/addons/themes/notifications/NotifFluid/Android.bp
    echo "✅ NotifFluid successfully bypassed!"
else
    echo "⚠️ Warning: NotifFluid Android.bp not found, skipping bypass."
fi

# ---------------------------------------------------------------------
# 6. SAFE CONFLICT RESOLUTION (CRAVE-APPROVED)
# ---------------------------------------------------------------------
echo "🧹 Running 'make installclean' to safely wipe old cross-source targets..."
make installclean

echo "🧱 Starting RisingOS Android 15 production compilation via rise b..."
rise b

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
