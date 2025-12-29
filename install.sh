#!/bin/bash
#
# Dell Fan Control Installation Script
# Dell 风扇控制安装脚本
#
# Description / 描述:
#   Installs Dell PowerEdge fan control script and systemd service.
#   安装 Dell PowerEdge 风扇控制脚本和 systemd 服务。
#
# Usage / 用法:
#   sudo ./install.sh
#
# Remote install / 远程安装:
#   wget -qO- https://raw.githubusercontent.com/Evil0ctal/Dell-Fan-Control/main/install.sh | sudo bash
#   curl -fsSL https://raw.githubusercontent.com/Evil0ctal/Dell-Fan-Control/main/install.sh | sudo bash
#

set -e

# ============================================================================
# Variables / 变量
# ============================================================================

SCRIPT_NAME="dell-fan-control.sh"
SERVICE_NAME="dell-fan.service"
INSTALL_DIR="/usr/local/bin"
SERVICE_DIR="/etc/systemd/system"
REPO_URL="https://raw.githubusercontent.com/Evil0ctal/Dell-Fan-Control/main"

# Colors for output / 输出颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================================================
# Functions / 函数
# ============================================================================

# Print colored message / 打印彩色消息
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
        print_info "Usage / 用法: sudo ./install.sh"
        exit 1
    fi
}

# Check if required commands exist / 检查必需的命令是否存在
check_dependencies() {
    print_info "Checking dependencies / 检查依赖..."

    local missing_deps=()

    if ! command -v ipmitool &> /dev/null; then
        missing_deps+=("ipmitool")
    fi

    if ! command -v sensors &> /dev/null; then
        missing_deps+=("lm-sensors")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_warn "Missing dependencies / 缺少依赖: ${missing_deps[*]}"
        print_info "Installing dependencies / 正在安装依赖..."

        apt update
        apt install -y ipmitool lm-sensors

        # Detect sensors / 检测传感器
        print_info "Detecting sensors / 正在检测传感器..."
        sensors-detect --auto
    fi

    print_info "All dependencies satisfied / 所有依赖已满足"
}

# Download file from repository / 从仓库下载文件
download_file() {
    local filename=$1
    local url="${REPO_URL}/${filename}"

    print_info "Downloading ${filename} / 正在下载 ${filename}..."

    if command -v wget &> /dev/null; then
        wget -q -O "/tmp/${filename}" "${url}"
    elif command -v curl &> /dev/null; then
        curl -fsSL -o "/tmp/${filename}" "${url}"
    else
        print_error "Neither wget nor curl found / 未找到 wget 或 curl"
        exit 1
    fi
}

# Install the script / 安装脚本
install_script() {
    print_info "Installing fan control script / 正在安装风扇控制脚本..."

    # Check if script exists locally, otherwise download / 检查脚本是否存在于本地，否则下载
    if [ -f "$SCRIPT_NAME" ]; then
        cp "$SCRIPT_NAME" "$INSTALL_DIR/"
    else
        download_file "$SCRIPT_NAME"
        cp "/tmp/$SCRIPT_NAME" "$INSTALL_DIR/"
        rm -f "/tmp/$SCRIPT_NAME"
    fi

    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

    print_info "Script installed to / 脚本已安装到: $INSTALL_DIR/$SCRIPT_NAME"
}

# Install systemd service / 安装 systemd 服务
install_service() {
    print_info "Installing systemd service / 正在安装 systemd 服务..."

    # Check if service file exists locally, otherwise download / 检查服务文件是否存在于本地，否则下载
    if [ -f "$SERVICE_NAME" ]; then
        cp "$SERVICE_NAME" "$SERVICE_DIR/"
    else
        download_file "$SERVICE_NAME"
        cp "/tmp/$SERVICE_NAME" "$SERVICE_DIR/"
        rm -f "/tmp/$SERVICE_NAME"
    fi

    # Reload systemd / 重新加载 systemd
    systemctl daemon-reload

    # Enable service / 启用服务
    systemctl enable dell-fan

    print_info "Service installed and enabled / 服务已安装并启用"
}

# Start the service / 启动服务
start_service() {
    print_info "Starting fan control service / 正在启动风扇控制服务..."

    systemctl start dell-fan

    # Check status / 检查状态
    if systemctl is-active --quiet dell-fan; then
        print_info "Service started successfully / 服务启动成功"
    else
        print_error "Service failed to start / 服务启动失败"
        print_info "Check logs with / 使用以下命令查看日志: journalctl -u dell-fan -f"
        exit 1
    fi
}

# Display status / 显示状态
show_status() {
    echo ""
    print_info "=========================================="
    print_info "Installation complete! / 安装完成！"
    print_info "=========================================="
    echo ""
    print_info "Service status / 服务状态:"
    systemctl status dell-fan --no-pager
    echo ""
    print_info "Useful commands / 有用的命令:"
    echo "  - Check status / 查看状态:   sudo systemctl status dell-fan"
    echo "  - View logs / 查看日志:      sudo journalctl -u dell-fan -f"
    echo "  - Restart / 重启:            sudo systemctl restart dell-fan"
    echo "  - Stop / 停止:               sudo systemctl stop dell-fan"
    echo "  - Monitor / 监控:            watch -n 5 'sensors | grep -E \"Package|Composite\"'"
    echo ""
}

# ============================================================================
# Main / 主程序
# ============================================================================

echo ""
echo "==========================================="
echo " Dell PowerEdge Fan Control Installer"
echo " Dell PowerEdge 风扇控制安装程序"
echo "==========================================="
echo ""

# Run installation steps / 运行安装步骤
check_root
check_dependencies
install_script
install_service
start_service
show_status

exit 0
