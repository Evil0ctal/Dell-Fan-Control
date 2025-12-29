# Dell PowerEdge 风扇控制

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.linux.org/)

适用于运行 Proxmox VE 或其他 Linux 发行版的 Dell PowerEdge 服务器（R730xd、R730、R630 等）的动态风扇控制方案。

[English](README.md)

## 问题

Dell PowerEdge 服务器在安装第三方 PCIe 设备（如 NVMe SSD）时，通常会将风扇转速拉满（9600+ RPM），即使温度很低也会产生很大噪音。

## 解决方案

本脚本根据 CPU 和 NVMe 温度提供动态风扇控制，在散热性能和噪音之间取得平衡。

## 功能

- 🌡️ 同时监控 CPU 和 NVMe 温度
- 🔄 根据温度动态调节风扇转速
- 🔇 禁用 Dell 对第三方 PCIe 设备的激进风扇响应
- 🚀 通过 systemd 实现开机自启
- ⚙️ 可配置的温度阈值

## 依赖

- 带有 iDRAC 的 Dell PowerEdge 服务器
- `ipmitool` 软件包
- `lm-sensors` 软件包

## 安装

### 一键安装（推荐）

**使用 wget：**
```bash
wget -qO- https://raw.githubusercontent.com/Evil0ctal/Dell-Fan-Control/main/install.sh | sudo bash
```

**使用 curl：**
```bash
curl -fsSL https://raw.githubusercontent.com/Evil0ctal/Dell-Fan-Control/main/install.sh | sudo bash
```

### 快速安装

```bash
# 克隆仓库
git clone https://github.com/Evil0ctal/Dell-Fan-Control.git
cd Dell-Fan-Control

# 运行安装脚本
sudo ./install.sh
```

### 手动安装

```bash
# 安装依赖
apt install ipmitool lm-sensors -y

# 检测传感器
sensors-detect --auto

# 复制脚本
sudo cp dell-fan-control.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/dell-fan-control.sh

# 复制 systemd 服务
sudo cp dell-fan.service /etc/systemd/system/

# 启用并启动服务
sudo systemctl daemon-reload
sudo systemctl enable dell-fan
sudo systemctl start dell-fan
```

## 风扇转速策略

| 温度 | 风扇转速 | 场景 |
|------|----------|------|
| < 55°C | 30% | 空闲 |
| 55-60°C | 35% | 轻负载 |
| 60-65°C | 40% | 一般负载 |
| 65-68°C | 50% | 中等负载 |
| 68-72°C | 60% | 较高负载 |
| 72-75°C | 70% | 高负载 |
| 75-80°C | 80% | 很高负载 |
| 80-85°C | 90% | 极限负载 |
| ≥ 85°C | 100% | 保护模式 |

## 使用

### 查看服务状态

```bash
sudo systemctl status dell-fan
```

### 查看日志

```bash
sudo journalctl -u dell-fan -f
```

### 监控温度和风扇

```bash
watch -n 5 'echo "=== CPU ===" && sensors | grep "Package id" && echo "=== NVMe ===" && sensors | grep "Composite" && echo "=== Fans ===" && ipmitool sensor | grep Fan | grep RPM'
```

### 手动设置风扇转速

```bash
# 启用手动控制
ipmitool raw 0x30 0x30 0x01 0x00

# 设置风扇转速（0x1e = 30%，0x32 = 50%，0x64 = 100%）
ipmitool raw 0x30 0x30 0x02 0xff 0x1e

# 恢复自动控制
ipmitool raw 0x30 0x30 0x01 0x01
```

### 风扇转速参考

| 百分比 | 十六进制 |
|--------|----------|
| 15% | 0x0f |
| 20% | 0x14 |
| 25% | 0x19 |
| 30% | 0x1e |
| 35% | 0x23 |
| 40% | 0x28 |
| 50% | 0x32 |
| 60% | 0x3c |
| 70% | 0x46 |
| 80% | 0x50 |
| 90% | 0x5a |
| 100% | 0x64 |

## 配置

编辑脚本以自定义温度阈值：

```bash
sudo nano /usr/local/bin/dell-fan-control.sh
```

## 测试环境

- Dell PowerEdge R730xd
- Dell PowerEdge R730
- Dell PowerEdge R630
- Proxmox VE 8.x / 9.x
- Debian 12 (Bookworm)
- Ubuntu 24.04 LTS

## 警告

⚠️ **使用风险自负！** 如果配置不当，手动风扇控制可能导致过热。安装后请密切监控温度。

## 卸载

**使用卸载脚本：**
```bash
cd Dell-Fan-Control
sudo ./uninstall.sh
```

**或手动卸载：**
```bash
sudo systemctl stop dell-fan
sudo systemctl disable dell-fan
sudo rm /etc/systemd/system/dell-fan.service
sudo rm /usr/local/bin/dell-fan-control.sh
sudo systemctl daemon-reload

# 恢复自动风扇控制
ipmitool raw 0x30 0x30 0x01 0x01
```

## 贡献

欢迎提交 Pull Request！请随时提交问题和功能请求。

## 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 致谢

- Dell IPMI 文档
- Proxmox VE 社区
- 所有贡献者

## 相关项目

- [ipmitool](https://github.com/ipmitool/ipmitool)
- [lm-sensors](https://github.com/lm-sensors/lm-sensors)
