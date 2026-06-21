# Redmi K50 DroidSpaces 内核

为 Redmi K50 (rubens) 构建的支持 [DroidSpaces](https://github.com/ravindu644/Droidspaces-OSS) 容器运行时的自定义内核。

## 什么是 DroidSpaces？

DroidSpaces 是一个轻量级的 Linux 容器运行时，可以在 Android 上运行完整的 Linux 发行版（支持 systemd、OpenRC 等），通过 Linux namespace 实现进程隔离。

## 设备信息

| 项目 | 信息 |
|------|------|
| 设备 | Redmi K50 |
| 代号 | rubens |
| SoC | MediaTek MT6983 |
| 内核版本 | 5.10.x (GKI) |
| 架构 | arm64 |

## 快速开始

### 方法 1: 使用 GitHub Actions 自动构建

1. Fork 本仓库
2. 推送到 `main` 分支，或手动触发 Actions
3. 等待构建完成（约 2-4 小时）
4. 从 Actions 页面下载 `droidspaces-k50-kernel.zip`

### 方法 2: 本地构建

```bash
# 克隆本仓库
git clone <your-repo-url>
cd app3

# 克隆内核源码
git clone --depth=1 --branch rubens-s-oss \
  https://github.com/MiCode/Xiaomi_Kernel_OpenSource.git kernel

# 下载 DroidSpaces 补丁
cd kernel/patches
curl -sL "https://raw.githubusercontent.com/ravindu644/Droidspaces-OSS/main/Documentation/resources/kernel-patches/GKI/below-kernel-6.12/001.GKI-below-6.12-fix_sysvipc_kabi_6_7_8.patch" -o "001.patch"
curl -sL "https://raw.githubusercontent.com/ravindu644/Droidspaces-OSS/main/Documentation/resources/kernel-patches/GKI/below-kernel-6.12/002.5.10_or_lower_use_android_abi_padding_for_posix_mqueue.patch" -o "002.patch"
cd ..

# 应用补丁
patch -p1 < patches/001.patch
patch -p1 < patches/002.patch

# 应用 DroidSpaces 配置
cat ../droidspaces.config >> arch/arm64/configs/mikrn_rubens_defconfig

# 编译
make ARCH=arm64 mikrn_rubens_defconfig
make ARCH=arm64 -j$(nproc) \
  CC=clang \
  CROSS_COMPILE=aarch64-linux-gnu- \
  LLVM=1 \
  LLVM_IAS=1 \
  Image
```

## 刷入方法

```bash
# 备份原厂 boot.img
adb reboot bootloader
fastboot boot backup boot.img

# 刷入新内核
fastboot flash boot boot.img
fastboot reboot
```

## 验证 DroidSpaces 支持

1. 安装 [DroidSpaces Android App](https://github.com/ravindu644/Droidspaces-OSS/releases/latest)
2. 确保设备已 Root (KernelSU/Magisk)
3. 打开 DroidSpaces → Settings → Requirements → Check Requirements
4. 所有项目应显示绿色 ✓

## 已启用的 DroidSpaces 功能

| 功能 | 状态 | 说明 |
|------|------|------|
| PID/MNT/UTS/IPC Namespace | ✅ | 容器核心隔离 |
| Network Namespace | ✅ | NAT/None 网络模式 |
| Cgroup 支持 | ✅ | 资源限制和隔离 |
| devtmpfs | ✅ | 设备文件系统 |
| Seccomp | ✅ | 系统调用过滤 |
| OverlayFS | ✅ | Volatile 模式支持 |
| VETH/Bridge | ✅ | NAT 网络支持 |

## 文件结构

```
app3/
├── .github/workflows/
│   └── build-kernel.yml      # GitHub Actions 自动构建
├── scripts/
│   └── build-kernel.sh       # 本地构建脚本
├── droidspaces.config        # DroidSpaces 内核配置片段
└── README.md                 # 本文档
```

## 常见问题

### Q: 刷入后无法开机怎么办？
A: 通过 fastboot 恢复原厂 boot.img：
```bash
fastboot flash boot stock_boot.img
fastboot reboot
```

### Q: DroidSpaces 显示某些功能不可用？
A: 检查内核配置是否包含所有必需选项，参考 `droidspaces.config`。

### Q: 如何更新内核？
A: 更新内核源码后重新构建，或从 GitHub Actions 下载最新构建。

## 参考资料

- [DroidSpaces-OSS](https://github.com/ravindu644/Droidspaces-OSS) — 容器运行时
- [DroidSpaces 内核配置指南](https://github.com/ravindu644/Droidspaces-OSS/blob/main/Documentation/Kernel-Configuration.md)
- [Android 内核编译教程](https://github.com/ravindu644/Android-Kernel-Tutorials)
- [小米内核源码](https://github.com/MiCode/Xiaomi_Kernel_OpenSource) — 分支 `rubens-s-oss`

## 许可证

本项目的内核配置遵循 GPLv2 许可证（与 Linux 内核一致）。
DroidSpaces 补丁遵循 GPLv3 许可证。
