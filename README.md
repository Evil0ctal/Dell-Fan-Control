# Dell PowerEdge Fan Control

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.linux.org/)

A dynamic fan control solution for Dell PowerEdge servers (R730xd, R730, R630, etc.) running Proxmox VE or other Linux distributions.

[中文文档](README_ZH.md)

## Problem

Dell PowerEdge servers often run fans at maximum speed (9600+ RPM) when third-party PCIe devices (like NVMe SSDs) are installed, causing excessive noise even when temperatures are low.

## Solution

This script provides dynamic fan control based on CPU and NVMe temperatures, balancing cooling performance with noise levels.

## Features

- 🌡️ Monitors both CPU and NVMe temperatures
- 🔄 Dynamic fan speed adjustment based on temperature
- 🔇 Disables Dell's aggressive third-party PCIe fan response
- 🚀 Automatic startup via systemd
- ⚙️ Configurable temperature thresholds

## Requirements

- Dell PowerEdge server with iDRAC
- `ipmitool` package
- `lm-sensors` package

## Installation

### One-Line Install (Recommended)

**Using wget:**
```bash
wget -qO- https://raw.githubusercontent.com/Evil0ctal/Dell-Fan-Control/main/install.sh | sudo bash
```

**Using curl:**
```bash
curl -fsSL https://raw.githubusercontent.com/Evil0ctal/Dell-Fan-Control/main/install.sh | sudo bash
```

### Quick Install

```bash
# Clone the repository
git clone https://github.com/Evil0ctal/Dell-Fan-Control.git
cd Dell-Fan-Control

# Run installer
sudo ./install.sh
```

### Manual Install

```bash
# Install dependencies
apt install ipmitool lm-sensors -y

# Detect sensors
sensors-detect --auto

# Copy script
sudo cp dell-fan-control.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/dell-fan-control.sh

# Copy systemd service
sudo cp dell-fan.service /etc/systemd/system/

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable dell-fan
sudo systemctl start dell-fan
```

## Fan Speed Strategy

| Temperature | Fan Speed | Scenario |
|-------------|-----------|----------|
| < 55°C | 30% | Idle |
| 55-60°C | 35% | Light load |
| 60-65°C | 40% | Normal load |
| 65-68°C | 50% | Medium load |
| 68-72°C | 60% | High load |
| 72-75°C | 70% | Heavy load |
| 75-80°C | 80% | Very heavy load |
| 80-85°C | 90% | Extreme load |
| ≥ 85°C | 100% | Protection mode |

## Usage

### Check Service Status

```bash
sudo systemctl status dell-fan
```

### View Logs

```bash
sudo journalctl -u dell-fan -f
```

### Monitor Temperatures and Fans

```bash
watch -n 5 'echo "=== CPU ===" && sensors | grep "Package id" && echo "=== NVMe ===" && sensors | grep "Composite" && echo "=== Fans ===" && ipmitool sensor | grep Fan | grep RPM'
```

### Manually Set Fan Speed

```bash
# Enable manual control
ipmitool raw 0x30 0x30 0x01 0x00

# Set fan speed (0x1e = 30%, 0x32 = 50%, 0x64 = 100%)
ipmitool raw 0x30 0x30 0x02 0xff 0x1e

# Restore automatic control
ipmitool raw 0x30 0x30 0x01 0x01
```

### Fan Speed Reference

| Percentage | Hex Value |
|------------|-----------|
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

## Configuration

Edit the script to customize temperature thresholds:

```bash
sudo nano /usr/local/bin/dell-fan-control.sh
```

## Tested On

- Dell PowerEdge R730xd
- Dell PowerEdge R730
- Dell PowerEdge R630
- Proxmox VE 8.x / 9.x
- Debian 12 (Bookworm)
- Ubuntu 24.04 LTS

## Warning

⚠️ **Use at your own risk!** Manual fan control can lead to overheating if not configured properly. Monitor your temperatures closely after installation.

## Uninstall

**Using the uninstall script:**
```bash
cd Dell-Fan-Control
sudo ./uninstall.sh
```

**Or manually:**
```bash
sudo systemctl stop dell-fan
sudo systemctl disable dell-fan
sudo rm /etc/systemd/system/dell-fan.service
sudo rm /usr/local/bin/dell-fan-control.sh
sudo systemctl daemon-reload

# Restore automatic fan control
ipmitool raw 0x30 0x30 0x01 0x01
```

## Contributing

Pull requests are welcome! Please feel free to submit issues and feature requests.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- Dell IPMI documentation
- Proxmox VE community
- All contributors

## Related Projects

- [ipmitool](https://github.com/ipmitool/ipmitool)
- [lm-sensors](https://github.com/lm-sensors/lm-sensors)
