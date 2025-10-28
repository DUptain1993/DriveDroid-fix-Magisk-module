

## DriveDroid Fix

### Features:
- Installs service to get DriveDroid app working again
- Automatically restores previous state of USB host after app termination
- Enhanced logging for troubleshooting (v2.0+)
- Full Android 15 support with improved error handling
- Compatible with both standard Android and Samsung devices

### Prerequisites:
 - Android 10-15 (API 29-35) - Preferably AOSP version
 - Magisk-powered root (Magisk 25+ recommended)
 - Latest DriveDroid installed on your device
 - Device must support USB gadget configfs (/config/usb_gadget/)

### Hardware

**Specifically Optimized For:**
- **Motorola Moto G 2025 (kansas)** - Full Android 15 support with device-specific optimizations

A list of other devices with confirmed (full or partial) compatibility is available [here](https://raw.githubusercontent.com/overzero-git/DriveDroid-fix-Magisk-module/main/tested_hardware).

### How to use:
1. Install module via Magisk
2. Reboot device as Magisk requires
3. Install DriveDroid app (if not already installed)
4. Configure app as usual, in hosting options select "Standard Android (Kernel)"
5. Mount an ISO image and enjoy!

### Troubleshooting:
- **Check logs**: View `/data/adb/fixdd.log` for detailed service logs (includes device info, USB paths, and operation status)
- **SELinux issues**: If you encounter problems, check for SELinux denials using `dmesg | grep avc`
- **USB not working**: Ensure your device supports USB gadget mode and the cable supports data transfer
- **Samsung devices**: Module includes special support for Samsung's mass_storage.usb0 variant
- **Motorola devices**:
  - Module automatically detects Motorola hardware and applies optimizations
  - Extended 15-second USB initialization delay (vs 10s on other devices)
  - Checks alternative USB gadget paths (/config/usb_gadget/g0, /sys/kernel/config/usb_gadget/g1)
  - Enhanced USB controller auto-detection for Motorola's USB implementation
  - **Moto G 2025 (kansas)**: Fully tested and optimized
- **Android 15**: Enhanced logging and error handling included for latest Android version

### Installation:
Like every Magisk module - download [latest release here](https://github.com/overzero-git/DriveDroid-fix-Magisk-module/releases/latest), then just install downloaded .zip in Magisk.

### Changelog:
**v2.0 (Android 15 + Motorola Moto G 2025 Update)**
- Added full Android 15 (API 35) support
- **Motorola Moto G 2025 (kansas) specific optimizations:**
  - Device detection and automatic configuration
  - Alternative USB gadget path support (/config/usb_gadget/g0, g1, /sys/kernel/config)
  - Extended USB initialization delay (15s for Motorola devices)
  - Enhanced USB controller auto-detection
  - Motorola-specific UDC controller handling
- Implemented comprehensive logging system (`/data/adb/fixdd.log`)
  - Logs device model, manufacturer, and Android version
  - Tracks USB gadget paths and controller detection
  - Records all mass_storage operations
- Enhanced error handling and SELinux denial detection
- Improved compatibility checks during installation
- Dynamic USB path resolution (no hardcoded paths)
- Better debugging capabilities for troubleshooting
- Fixed typo: "Standart" → "Standard"

### Donations:
  
The module was and will remain completely free, however, at the request of some people, I am leaving the BTC address here - if anyone wants to thank financially, you are welcome. It's still not necessary.

BTC Address: 
bc1qn3xdw34y6xmwly5cgnk9see9njr7y5jj4ts7kf
