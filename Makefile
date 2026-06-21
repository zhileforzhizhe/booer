# Redmi K50 DroidSpaces Kernel - Top-level Makefile
# Provides convenient targets for local development

KERNEL_REPO := https://github.com/MiCode/Xiaomi_Kernel_OpenSource.git
KERNEL_BRANCH := rubens-s-oss
DEFCONFIG := mikrn_rubens_defconfig
ARCH := arm64
OUTPUT_DIR := output

.PHONY: all clone patch config build clean help

all: clone patch config build ## Full build pipeline

help: ## Show this help
	@echo "Redmi K50 DroidSpaces Kernel Builder"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Quick start:"
	@echo "  make all          # Clone, patch, configure, and build"
	@echo "  make build        # Just build (if already configured)"

clone: ## Clone kernel source
	@if [ ! -d "kernel" ]; then \
		echo "Cloning kernel source..."; \
		git clone --depth=1 --branch $(KERNEL_BRANCH) $(KERNEL_REPO) kernel; \
	else \
		echo "Kernel source already exists."; \
	fi

patch: clone ## Download and apply DroidSpaces patches
	@echo "Applying DroidSpaces patches..."
	@mkdir -p kernel/patches
	@cd kernel/patches && \
	curl -sL "https://raw.githubusercontent.com/ravindu644/Droidspaces-OSS/main/Documentation/resources/kernel-patches/GKI/below-kernel-6.12/001.GKI-below-6.12-fix_sysvipc_kabi_6_7_8.patch" -o "001.patch" && \
	curl -sL "https://raw.githubusercontent.com/ravindu644/Droidspaces-OSS/main/Documentation/resources/kernel-patches/GKI/below-kernel-6.12/002.5.10_or_lower_use_android_abi_padding_for_posix_mqueue.patch" -o "002.patch"
	@cd kernel && (patch -p1 < patches/001.patch || true) && (patch -p1 < patches/002.patch || true)
	@echo "Patches applied."

config: patch ## Apply DroidSpaces config to defconfig
	@echo "Applying DroidSpaces configuration..."
	@echo "" >> kernel/arch/arm64/configs/$(DEFCONFIG)
	@echo "# DroidSpaces container support" >> kernel/arch/arm64/configs/$(DEFCONFIG)
	@cat droidspaces.config >> kernel/arch/arm64/configs/$(DEFCONFIG)
	@echo "Configuration applied."

build: ## Build the kernel
	@echo "Building kernel..."
	@cd kernel && \
	make ARCH=$(ARCH) $(DEFCONFIG) && \
	make ARCH=$(ARCH) -j$$(nproc) \
		CC=clang \
		CROSS_COMPILE=aarch64-linux-gnu- \
		CROSS_COMPILE_ARM32=arm-linux-gnueabihf- \
		LLVM=1 \
		LLVM_IAS=1 \
		Image
	@mkdir -p $(OUTPUT_DIR)
	@cp kernel/arch/arm64/boot/Image $(OUTPUT_DIR)/
	@echo "Build complete! Output: $(OUTPUT_DIR)/Image"

package: build ## Package kernel as zip
	@echo "Packaging kernel..."
	@mkdir -p $(OUTPUT_DIR)/dtbs
	@find kernel/arch/arm64/boot/dts -name "*.dtb" -exec cp {} $(OUTPUT_DIR)/dtbs/ \; 2>/dev/null || true
	@cp kernel/arch/arm64/configs/$(DEFCONFIG) $(OUTPUT_DIR)/droidspaces_defconfig
	@cd $(OUTPUT_DIR) && zip -r ../droidspaces-k50-kernel.zip .
	@echo "Package created: droidspaces-k50-kernel.zip"

clean: ## Clean build artifacts
	@echo "Cleaning..."
	@if [ -d "kernel" ]; then cd kernel && make ARCH=$(ARCH) clean; fi
	@rm -rf $(OUTPUT_DIR)
	@rm -f droidspaces-k50-kernel.zip
	@echo "Clean."

distclean: clean ## Remove everything including cloned source
	@rm -rf kernel
	@echo "Dist clean."
