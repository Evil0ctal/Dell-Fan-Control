#!/bin/bash
#
# Dell Fan Control Uninstallation Script
# Dell 风扇控制卸载脚本
#
# Description / 描述:
#   Uninstalls Dell PowerEdge fan control script and restores automatic control.
#   卸载 Dell PowerEdge 风扇控制脚本并恢复自动控制。
#
# Usage / 用法:
#   sudo ./uninstall.sh
#

set -e

# ============================================================================
# Variables / 变量
# ============================================================================

SCRIPT_NAME="dell-fan-control.sh"
SERVICE_NAME="dell-fan"
INSTALL_DIR="/usr/local/bin"
SERVICE_DIR="/etc/systemd/system"

# Colors for output / 输出颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================================================
# Functions / 函数
# ============================================================================

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root / 检查是否以 root 运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root / 请以 root 用户运行"
        exit 1
    fi
}

# ============================================================================
# Main / 主程序
# ============================================================================

echo ""
echo "==========================================="
echo " Dell PowerEdge Fan Control Uninstaller"
echo " Dell PowerEdge 风扇控制卸载程序"
echo "==========================================="
echo ""

check_root

# Stop service / 停止服务
print_info "Stopping service / 正在停止服务..."
systemctl stop "$SERVICE_NAME" 2>/dev/null || true

# Disable service / 禁用服务
print_info "Disabling service / 正在禁用服务..."
systemctl disable "$SERVICE_NAME" 2>/dev/null || true

# Remove service file / 删除服务文件
print_info "Removing service file / 正在删除服务文件..."
rm -f "$SERVICE_DIR/$SERVICE_NAME.service"

# Remove script / 删除脚本
print_info "Removing script / 正在删除脚本..."
rm -f "$INSTALL_DIR/$SCRIPT_NAME"

# Reload systemd / 重新加载 systemd
print_info "Reloading systemd / 正在重新加载 systemd..."
systemctl daemon-reload

# Restore automatic fan control / 恢复自动风扇控制
print_info "Restoring automatic fan control / 正在恢复自动风扇控制..."
ipmitool raw 0x30 0x30 0x01 0x01

echo ""
print_info "=========================================="
print_info "Uninstallation complete! / 卸载完成！"
print_info "=========================================="
echo ""
print_info "Automatic fan control has been restored."
print_info "已恢复自动风扇控制。"
echo ""

exit 0
