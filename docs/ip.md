# Guide for Setting Up Static IP

## Overview

This guide will walk you through the process of configuring a static IP address on your system. Please follow these instructions carefully to avoid network connectivity issues.

## Prerequisites

- Administrative access to your router
- Command line access to your system
- Basic understanding of your network configuration

## Step-by-Step Instructions

### 1. Identify Your Network Interface

First, you need to identify the correct network interface name on your system. You can view your network interfaces in the terminal:

![Network Interface Display](https://www.linuxtechi.com/wp-content/uploads/2021/08/IP-Command-Output-Debian12-Command-Line.png)

**Important Notes:**

- Look for interfaces like `enp0s3` or `eth0`
- Do NOT use interfaces like `docker0` as this can break SSH connectivity
- Your interface name may differ from the example shown

### 2. Configuration Process

When running the setup:

1. Enter your network interface name when prompted
2. Specify your desired static IP address (e.g., 192.168.1.240)
3. Provide your router's admin interface IP address

### 3. Verification

After configuration, verify your connection to ensure everything is working properly.

## Important Considerations

- Back up your current network configuration before making changes
- Ensure your chosen static IP is not in use by another device
- Make sure the IP address is within your network's valid range

## Troubleshooting

If you lose connectivity:

- Check your router's DHCP settings
- Verify your network interface configuration
- Ensure there are no IP conflicts on your network
