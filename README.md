# Raspberry Pi Network Setup Script

A simple Bash script for managing static IP configuration on Raspberry Pi using NetworkManager.


## Installation

Run the script directly using:

```bash
bash <(curl -s https://raw.githubusercontent.com/g-flame-oss/rpi-options/refs/heads/main/script.sh)
```

## Features

- Set static IP addresses via dialog menus
- Validate input (IP, gateway, DNS)
- View current network status
- Safe handling of interface reconfiguration
- Support for headless or SSH-based setup (with warnings)

## Requirements

- Root privileges
- `dialog`
- `NetworkManager` (will prompt to install if missing)

