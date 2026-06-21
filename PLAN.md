# Redmi K50 DroidSpaces 内核构建计划

## 目标
为 Redmi K50 (rubens, MT6983/Dimensity) 构建支持 DroidSpaces 容器运行时的自定义内核。

## 设备信息
- **设备**: Redmi K50
- **代号**: rubens
- **SoC**: MediaTek (MT6983 平台)
- **内核版本**: 5.10.x (GKI 架构)
- **架构**: arm64
- **内核源码**: `MiCode/Xiaomi_Kernel_OpenSource` 分支 `rubens-s-oss`
- **defconfig**: `mikrn_rubens_defconfig`

## 构建方式
使用 **GitHub Actions** 自动化构建，无需本地 Linux 环境。

## 实施步骤

### 步骤 1: 创建 GitHub Actions 工作流
创建 `.github/workflows/build-kernel.yml`，包含：
1. 克隆小米内核源码 (`rubens-s-oss` 分支)
2. 下载 DroidSpaces GKI 补丁
3. 应用 kABI 补丁和配置修改
4. 编译内核
5. 打包为可刷入的 boot.img

### 步骤 2: 应用 DroidSpaces 补丁
从 `ravindu644/Droidspaces-OSS` 获取并应用：
- `001.GKI-below-6.12-fix_sysvipc_kABI_6_7_8.patch` — SYSVIPC kABI 修复
- `002.5.10_or_lower_use_android_abi_padding_for_posix_mqueue.patch` — POSIX_MQUEUE 修复 (5.10 必须)

### 步骤 3: 修改内核配置
在 `mikrn_rubens_defconfig` 中添加：
```makefile
# DroidSpaces 必需配置
CONFIG_SYSVIPC=y
CONFIG_POSIX_MQUEUE=y
CONFIG_IPC_NS=y
CONFIG_PID_NS=y
CONFIG_DEVTMPFS=y
CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y

# 可选: UFW/Fail2ban 支持
CONFIG_NETFILTER_XT_TARGET_REJECT=y
CONFIG_NETFILTER_XT_TARGET_LOG=y
CONFIG_NETFILTER_XT_MATCH_RECENT=y
CONFIG_IP_SET=y
CONFIG_IP_SET_HASH_IP=y
CONFIG_IP_SET_HASH_NET=y
CONFIG_NETFILTER_XT_SET=y

# 可选: tmpfs xattr (NixOS 支持)
CONFIG_TMPFS_POSIX_ACL=y
CONFIG_TMPFS_XATTR=y
```

### 步骤 4: 编译与打包
- 使用 GKI 编译流程
- 生成 `boot.img`
- 上传为 GitHub Actions artifact

### 步骤 5: 刷入与验证
- `fastboot flash boot boot.img`
- 安装 DroidSpaces app
- 运行 Requirements Checker 验证

## 输出产物
- `boot.img` — 可直接 fastboot 刷入
- GitHub Actions 自动构建，每次 push 自动触发

## 风险提示
- 刷入前请备份原厂 boot.img
- GKI kABI 补丁兼容性已由 DroidSpaces 官方验证
- 如遇开机循环，可通过 fastboot 恢复原厂 boot.img
