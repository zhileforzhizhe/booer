#!/bin/bash
# Build script for Redmi K50 (rubens) kernel with DroidSpaces support
# This script is designed to run in GitHub Actions

set -e

echo "============================================"
echo " Redmi K50 DroidSpaces Kernel Builder"
echo "============================================"

# --- Configuration ---
KERNEL_REPO="https://github.com/MiCode/Xiaomi_Kernel_OpenSource.git"
KERNEL_BRANCH="rubens-s-oss"
DEFCONFIG="mikrn_rubens_defconfig"
ARCH="arm64"
SUBARCH="arm64"

# DroidSpaces patches
DROIDSPACES_PATCHES=(
    "https://raw.githubusercontent.com/ravindu644/Droidspaces-OSS/main/Documentation/resources/kernel-patches/GKI/below-kernel-6.12/001.GKI-below-6.12-fix_sysvipc_kabi_6_7_8.patch"
    "https://raw.githubusercontent.com/ravindu644/Droidspaces-OSS/main/Documentation/resources/kernel-patches/GKI/below-kernel-6.12/002.5.10_or_lower_use_android_abi_padding_for_posix_mqueue.patch"
)

# --- Step 1: Clone kernel source ---
echo "[1/6] Cloning kernel source..."
if [ ! -d "kernel" ]; then
    git clone --depth=1 --branch "$KERNEL_BRANCH" "$KERNEL_REPO" kernel
fi
cd kernel

# --- Step 2: Download and apply DroidSpaces patches ---
echo "[2/6] Applying DroidSpaces patches..."
mkdir -p patches
for i in "${!DROIDSPACES_PATCHES[@]}"; do
    url="${DROIDSPACES_PATCHES[$i]}"
    filename=$(basename "$url")
    echo "  Downloading: $filename"
    curl -sL "$url" -o "patches/$filename"
    echo "  Applying: $filename"
    patch -p1 < "patches/$filename" || {
        echo "  WARNING: Patch $filename may have already been applied or had conflicts."
        echo "  Continuing..."
    }
done

# --- Step 3: Apply DroidSpaces kernel config ---
echo "[3/6] Applying DroidSpaces kernel configuration..."
CONFIG_FILE="arch/arm64/configs/$DEFCONFIG"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Defconfig not found at $CONFIG_FILE"
    echo "Available defconfigs:"
    ls arch/arm64/configs/ | grep -i rubens
    exit 1
fi

# Append DroidSpaces config to defconfig
echo "" >> "$CONFIG_FILE"
echo "# DroidSpaces container support" >> "$CONFIG_FILE"
cat ../droidspaces.config >> "$CONFIG_FILE"

echo "  Config applied to $CONFIG_FILE"

# --- Step 4: Setup toolchain ---
echo "[4/6] Setting up toolchain..."

# Use Google's prebuilt clang if available, otherwise use system clang
if [ -d "prebuilts/clang/host/linux-x86" ]; then
    CLANG_DIR=$(ls -d prebuilts/clang/host/linux-x86/clang-* 2>/dev/null | sort -V | tail -1)
    if [ -n "$CLANG_DIR" ]; then
        export PATH="$CLANG_DIR/bin:$PATH"
        echo "  Using AOSP clang: $CLANG_DIR"
    fi
fi

# Check for cross-compile toolchain
if [ -d "prebuilts/gcc/linux-x86/aarch64" ]; then
    GCC_DIR=$(ls -d prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-* 2>/dev/null | sort -V | tail -1)
    if [ -n "$GCC_DIR" ]; then
        export PATH="$GCC_DIR/bin:$PATH"
        echo "  Using GCC cross-compiler: $GCC_DIR"
    fi
fi

# --- Step 5: Build kernel ---
echo "[5/6] Building kernel..."

# Generate .config from defconfig
make ARCH=$ARCH $DEFCONFIG

# Build with all available cores
make ARCH=$ARCH -j$(nproc) \
    CC=clang \
    CROSS_COMPILE=aarch64-linux-android- \
    CROSS_COMPILE_ARM32=arm-linux-androideabi- \
    LLVM=1 \
    LLVM_IAS=1 \
    Image 2>&1 | tail -50

# --- Step 6: Package ---
echo "[6/6] Packaging kernel..."

# Create output directory
mkdir -p ../output

# Copy kernel image
if [ -f "arch/arm64/boot/Image" ]; then
    cp arch/arm64/boot/Image ../output/
    echo "  Kernel image: output/Image"
fi

# Copy DTB/DTBO if they exist
if [ -f "arch/arm64/boot/dts/mediatek/mt6983.dtb" ]; then
    cp arch/arm64/boot/dts/mediatek/mt6983.dtb ../output/
fi

# Copy the defconfig with DroidSpaces options for reference
cp "$CONFIG_FILE" ../output/droidspaces_defconfig

echo ""
echo "============================================"
echo " Build Complete!"
echo "============================================"
echo ""
echo "Output files:"
ls -la ../output/
echo ""
echo "To flash: fastboot flash boot <boot.img>"
