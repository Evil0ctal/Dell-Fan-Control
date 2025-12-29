#!/bin/bash
#
# Dell PowerEdge Dynamic Fan Control Script
# Dell PowerEdge 动态风扇控制脚本
#
# Description / 描述:
#   This script provides dynamic fan control for Dell PowerEdge servers
#   based on CPU and NVMe temperatures. It disables Dell's aggressive
#   fan response to third-party PCIe devices.
#
#   本脚本为 Dell PowerEdge 服务器提供基于 CPU 和 NVMe 温度的动态风扇控制。
#   它禁用了 Dell 对第三方 PCIe 设备的激进风扇响应。
#
# Supported servers / 支持的服务器:
#   - Dell PowerEdge R730xd, R730, R630, etc.
#
# Requirements / 依赖:
#   - ipmitool
#   - lm-sensors
#
# Author / 作者: TikHub
# License / 许可证: MIT
# Repository / 仓库: https://github.com/Evil0ctal/Dell-Fan-Control
#

# ============================================================================
# Configuration / 配置
# ============================================================================

# Check interval in seconds / 检查间隔（秒）
CHECK_INTERVAL=15

# Enable logging (true/false) / 启用日志（true/false）
ENABLE_LOGGING=false

# Log file path / 日志文件路径
LOG_FILE="/var/log/dell-fan-control.log"

# ============================================================================
# Functions / 函数
# ============================================================================

# Function: Log message / 函数：记录日志
# Usage / 用法: log_message "message"
log_message() {
    if [ "$ENABLE_LOGGING" = true ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    fi
}

# Function: Disable Dell's third-party PCIe fan response
# 函数：禁用 Dell 对第三方 PCIe 设备的风扇响应
#
# Dell servers spin fans to maximum when detecting non-Dell PCIe devices
# Dell 服务器在检测到非 Dell PCIe 设备时会将风扇转速拉满
disable_pcie_fan_response() {
    ipmitool raw 0x30 0xce 0x00 0x16 0x05 0x00 0x00 0x00 0x05 0x00 0x01 0x00 0x00
    log_message "Disabled third-party PCIe fan response / 已禁用第三方 PCIe 风扇响应"
}

# Function: Enable manual fan control mode
# 函数：启用手动风扇控制模式
#
# Switches from automatic to manual fan control
# 从自动切换到手动风扇控制
enable_manual_fan_control() {
    ipmitool raw 0x30 0x30 0x01 0x00
    log_message "Enabled manual fan control / 已启用手动风扇控制"
}

# Function: Restore automatic fan control mode
# 函数：恢复自动风扇控制模式
#
# Returns control to Dell's automatic fan management
# 将控制权交还给 Dell 的自动风扇管理
restore_auto_fan_control() {
    ipmitool raw 0x30 0x30 0x01 0x01
    log_message "Restored automatic fan control / 已恢复自动风扇控制"
}

# Function: Set fan speed percentage
# 函数：设置风扇转速百分比
#
# Parameter / 参数: $1 - Hex value for fan speed (e.g., 0x1e for 30%)
#                      风扇转速的十六进制值（例如 0x1e 表示 30%）
#
# Fan speed reference / 风扇转速参考:
#   0x0f = 15%    0x14 = 20%    0x19 = 25%    0x1e = 30%
#   0x23 = 35%    0x28 = 40%    0x32 = 50%    0x3c = 60%
#   0x46 = 70%    0x50 = 80%    0x5a = 90%    0x64 = 100%
set_fan_speed() {
    ipmitool raw 0x30 0x30 0x02 0xff "$1"
}

# Function: Get maximum CPU temperature
# 函数：获取 CPU 最高温度
#
# Returns the highest temperature among all CPU packages
# 返回所有 CPU 封装中的最高温度
get_cpu_temp() {
    local temp
    temp=$(sensors | grep "Package id" | awk '{print $4}' | tr -d '+°C' | cut -d. -f1 | sort -rn | head -1)
    
    # Return default value if reading fails / 如果读取失败则返回默认值
    if [ -z "$temp" ]; then
        echo "70"
    else
        echo "$temp"
    fi
}

# Function: Get maximum NVMe temperature
# 函数：获取 NVMe 最高温度
#
# Returns the highest temperature among all NVMe devices
# 返回所有 NVMe 设备中的最高温度
get_nvme_temp() {
    local temp
    temp=$(sensors | grep "Composite" | awk '{print $2}' | tr -d '+°C' | cut -d. -f1 | sort -rn | head -1)
    
    # Return default value if reading fails / 如果读取失败则返回默认值
    if [ -z "$temp" ]; then
        echo "50"
    else
        echo "$temp"
    fi
}

# Function: Get maximum temperature (CPU or NVMe)
# 函数：获取最高温度（CPU 或 NVMe）
#
# Returns the higher value between CPU and NVMe temperatures
# 返回 CPU 和 NVMe 温度中的较高值
get_max_temp() {
    local cpu_temp
    local nvme_temp
    
    cpu_temp=$(get_cpu_temp)
    nvme_temp=$(get_nvme_temp)
    
    if [ "$nvme_temp" -gt "$cpu_temp" ]; then
        echo "$nvme_temp"
    else
        echo "$cpu_temp"
    fi
}

# Function: Determine fan speed based on temperature
# 函数：根据温度确定风扇转速
#
# Temperature thresholds and corresponding fan speeds:
# 温度阈值及对应的风扇转速：
#
#   >= 85°C  ->  100%  (Protection mode / 保护模式)
#   >= 80°C  ->   90%  (Extreme load / 极限负载)
#   >= 75°C  ->   80%  (Very heavy load / 很高负载)
#   >= 72°C  ->   70%  (Heavy load / 高负载)
#   >= 68°C  ->   60%  (High load / 较高负载)
#   >= 65°C  ->   50%  (Medium load / 中等负载)
#   >= 60°C  ->   40%  (Normal load / 一般负载)
#   >= 55°C  ->   35%  (Light load / 轻负载)
#   <  55°C  ->   30%  (Idle / 空闲)
#
# Parameter / 参数: $1 - Current temperature / 当前温度
adjust_fan_speed() {
    local temp=$1
    local speed_hex
    local speed_percent
    
    if [ "$temp" -ge 85 ]; then
        speed_hex="0x64"
        speed_percent="100"
    elif [ "$temp" -ge 80 ]; then
        speed_hex="0x5a"
        speed_percent="90"
    elif [ "$temp" -ge 75 ]; then
        speed_hex="0x50"
        speed_percent="80"
    elif [ "$temp" -ge 72 ]; then
        speed_hex="0x46"
        speed_percent="70"
    elif [ "$temp" -ge 68 ]; then
        speed_hex="0x3c"
        speed_percent="60"
    elif [ "$temp" -ge 65 ]; then
        speed_hex="0x32"
        speed_percent="50"
    elif [ "$temp" -ge 60 ]; then
        speed_hex="0x28"
        speed_percent="40"
    elif [ "$temp" -ge 55 ]; then
        speed_hex="0x23"
        speed_percent="35"
    else
        speed_hex="0x1e"
        speed_percent="30"
    fi
    
    set_fan_speed "$speed_hex"
    log_message "Temp: ${temp}°C -> Fan: ${speed_percent}% / 温度: ${temp}°C -> 风扇: ${speed_percent}%"
}

# Function: Cleanup on exit
# 函数：退出时清理
#
# Restores automatic fan control when script is terminated
# 脚本终止时恢复自动风扇控制
cleanup() {
    log_message "Script terminated, restoring auto fan control / 脚本终止，恢复自动风扇控制"
    restore_auto_fan_control
    exit 0
}

# ============================================================================
# Main / 主程序
# ============================================================================

# Trap signals for cleanup / 捕获信号以进行清理
trap cleanup SIGTERM SIGINT SIGHUP

# Initialize / 初始化
log_message "Starting Dell fan control script / 启动 Dell 风扇控制脚本"

# Disable third-party PCIe fan response / 禁用第三方 PCIe 风扇响应
disable_pcie_fan_response

# Enable manual fan control / 启用手动风扇控制
enable_manual_fan_control

# Main loop / 主循环
while true; do
    # Get current maximum temperature / 获取当前最高温度
    current_temp=$(get_max_temp)
    
    # Adjust fan speed based on temperature / 根据温度调整风扇转速
    adjust_fan_speed "$current_temp"
    
    # Wait before next check / 等待下次检查
    sleep "$CHECK_INTERVAL"
done
