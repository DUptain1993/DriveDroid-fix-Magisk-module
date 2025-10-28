#!/bin/sh

# Developed by mmtrt (https://gist.github.com/mmtrt)
# Improved by Danil Vyazikov (https://github.com/overzero-git/) and barsikus007 (https://gist.github.com/barsikus007/)
# Updated for Android 15 support
# Published under GPLv3

LOGFILE="/data/adb/fixdd.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOGFILE"
}

log "DriveDroid Fix service starting..."
log "Android SDK: $(getprop ro.build.version.sdk)"

# Device detection
DEVICE_MODEL=$(getprop ro.product.device)
DEVICE_MANUFACTURER=$(getprop ro.product.manufacturer)
DEVICE_NAME=$(getprop ro.product.model)

log "Device: $DEVICE_MANUFACTURER $DEVICE_NAME ($DEVICE_MODEL)"

# Motorola-specific detection
IS_MOTOROLA=0
IS_KANSAS=0
if [ "$DEVICE_MANUFACTURER" = "motorola" ] || [ "$DEVICE_MANUFACTURER" = "Motorola" ]; then
  IS_MOTOROLA=1
  log "Motorola device detected - applying Motorola-specific configurations"

  if [ "$DEVICE_MODEL" = "kansas" ]; then
    IS_KANSAS=1
    log "Motorola Moto G 2025 (kansas) detected - optimized support enabled"
  fi
fi

# run while loop for boot_completed status & sleep 10 needed for magisk service.d
while [ "$(getprop sys.boot_completed | tr -d '\r')" != "1" ]; do sleep 1; done

# Motorola devices may need extra time for USB initialization
if [ "$IS_MOTOROLA" -eq "1" ]; then
  sleep 15
  log "Extended wait for Motorola USB initialization"
else
  sleep 10
fi

log "Boot completed, initializing USB gadget monitoring..."

get_fn_type() {
  # get currently active function name
  if ls /config/usb_gadget/g1/configs/b.1/function* > /dev/null 2>&1
  then
    echo "function"
  else
    echo "f"
  fi
}

fn_type=$(get_fn_type)
log "Function type detected: $fn_type"

# Detect USB gadget path (Motorola may use different paths)
USB_GADGET_PATH="/config/usb_gadget/g1"

if [ ! -d "$USB_GADGET_PATH" ]; then
  log "Standard gadget path not found, checking alternatives..."

  # Check for alternative paths (some Motorola devices use these)
  if [ -d "/config/usb_gadget/g0" ]; then
    USB_GADGET_PATH="/config/usb_gadget/g0"
    log "Using alternative path: $USB_GADGET_PATH"
  elif [ -d "/sys/kernel/config/usb_gadget/g1" ]; then
    USB_GADGET_PATH="/sys/kernel/config/usb_gadget/g1"
    log "Using alternative path: $USB_GADGET_PATH"
  else
    log "ERROR: USB gadget path not found. Device may not support configfs."
    log "Checked paths: /config/usb_gadget/g1, /config/usb_gadget/g0, /sys/kernel/config/usb_gadget/g1"
    exit 1
  fi
fi

log "Using USB gadget path: $USB_GADGET_PATH"

# Update functions to use dynamic path
USB_CONFIG_PATH="$USB_GADGET_PATH/configs/b.1"
USB_FUNCTIONS_PATH="$USB_GADGET_PATH/functions"
USB_UDC_PATH="$USB_GADGET_PATH/UDC"

# Verify critical paths exist
if [ ! -d "$USB_CONFIG_PATH" ]; then
  log "ERROR: USB config path not found: $USB_CONFIG_PATH"
  exit 1
fi

get_chkfn() {
  # get currently active function name
  ls -al "$USB_CONFIG_PATH/" | grep -Eo "$fn_type[0-9]+[[:space:]].*" | awk '{print $3}' | cut -d/ -f8
}

get_last_fn() {
  # get currently free function number
  num=$(ls -al "$USB_CONFIG_PATH/" | grep -Eo "$fn_type[0-9]+[[:space:]]" | tail -1 | cut -dn -f 3)
  echo "$fn_type"$((num+1))
}

is_mass_storage_present() {
  # returns 1 if mass_storage.0 is present
  ls -al "$USB_CONFIG_PATH/" | grep -Eo "mass_storage.0" | wc -l
}

get_mass_storage_path() {
  # get path to mass_storage.0
  ls -al "$USB_CONFIG_PATH/" | grep -Eo "$fn_type[0-9]+[[:space:]].*mass_storage.0" | cut -d' ' -f1
}

#this options for some devices uses mass_storage.usb0 instead mass_storage.0 (some Samsung and Motorola devices for example)
is_mass_storage_usb0_present() {
  # returns 1 if mass_storage.usb0 is present
  ls -al "$USB_CONFIG_PATH/" | grep -Eo "mass_storage.usb0" | wc -l
}

get_mass_storage_usb0_path() {
  # get path to mass_storage.usb0
  ls -al "$USB_CONFIG_PATH/" | grep -Eo "$fn_type[0-9]+[[:space:]].*mass_storage.usb0" | cut -d' ' -f1
}

# save currently active function name
if [ "$fn_type" = "f" ]; then
  get_chkfn > /data/adb/.fixdd
fi

# loop
# run every 0.5 seconds
while true
do
  # check the app is active
  chkapp="$(pgrep -f drivedroid | wc -l)"
  
  # check if mass_storage.0 is active function
  mass_storage_active=$(is_mass_storage_present)
  if [ "$chkapp" -eq "1" ] && [ "$mass_storage_active" -eq "0" ]; then
    # add mass_storage.0 to currently active functions
    log "DriveDroid detected, enabling mass_storage..."

    if [ "$fn_type" = "f" ]; then
      setprop sys.usb.config cdrom
      setprop sys.usb.configfs 1
      rm "$USB_CONFIG_PATH/f*" 2>/dev/null
    fi

    # Create mass_storage function if it doesn't exist
    if [ ! -d "$USB_FUNCTIONS_PATH/mass_storage.0" ]; then
      mkdir -p "$USB_FUNCTIONS_PATH/mass_storage.0/lun.0/" 2>/dev/null
      if [ $? -ne 0 ]; then
        log "ERROR: Failed to create mass_storage.0 function (possible SELinux denial)"
      else
        log "Created mass_storage.0 function directory"
      fi
    fi

    ln -s "$USB_FUNCTIONS_PATH/mass_storage.0" "$USB_CONFIG_PATH/$(get_last_fn)" 2>/dev/null
    if [ $? -eq 0 ]; then
      log "mass_storage.0 function linked successfully"
    else
      log "WARNING: Failed to link mass_storage.0 (may already exist or SELinux denial)"
    fi

    if [ "$fn_type" = "f" ]; then
      # Motorola-specific USB controller detection
      USB_CONTROLLER=$(getprop sys.usb.controller)
      if [ -z "$USB_CONTROLLER" ]; then
        # Fallback: find controller from /sys/class/udc/
        USB_CONTROLLER=$(ls /sys/class/udc/ | head -1)
        log "USB controller auto-detected: $USB_CONTROLLER"
      else
        log "USB controller from property: $USB_CONTROLLER"
      fi

      echo "$USB_CONTROLLER" > "$USB_UDC_PATH"
      setprop sys.usb.state cdrom
    fi
  elif [ "$chkapp" -eq "0" ] && [ "$mass_storage_active" -eq "1" ]; then
    # remove mass_storage.0 function
    log "DriveDroid closed, restoring previous USB function..."

    rm "$USB_CONFIG_PATH/$(get_mass_storage_path)" 2>/dev/null
    if [ $? -eq 0 ]; then
      log "mass_storage.0 function removed successfully"
    else
      log "WARNING: Failed to remove mass_storage.0"
    fi

    # it seems, that pixel 7 doesn't use sys.usb.config at all
    if [ "$fn_type" = "f" ]; then
      # reload of configfs to fix samsung and motorola android auto
      setprop sys.usb.configfs 0
      sleep 0.5
      setprop sys.usb.configfs 1
      # load previous active function
      chkfrstfn="$(cat /data/adb/.fixdd)"
      log "Restoring USB function: $chkfrstfn"

      ln -s "$USB_FUNCTIONS_PATH/$chkfrstfn" "$USB_CONFIG_PATH/f1" 2>/dev/null
      if [ $? -ne 0 ]; then
        log "WARNING: Failed to restore function $chkfrstfn"
      fi

      # USB controller detection - Motorola may need different approach
      if [ "$IS_MOTOROLA" -eq "1" ]; then
        # Try to find any available UDC controller
        USB_CONTROLLER=$(ls /sys/class/udc/ | head -1)
        log "Motorola: Using UDC controller: $USB_CONTROLLER"
        echo "$USB_CONTROLLER" > "$USB_UDC_PATH" 2>/dev/null
      else
        # Standard approach for other devices
        ls /sys/class/udc/ | grep -Eo ".*\.dwc3" > "$USB_UDC_PATH" 2>/dev/null
        if [ $? -ne 0 ]; then
          # Fallback if dwc3 not found
          ls /sys/class/udc/ | head -1 > "$USB_UDC_PATH" 2>/dev/null
          log "Using fallback UDC controller"
        fi
      fi

      setprop sys.usb.state mtp
      if [ "$chkfrstfn" = "ffs.adb" ]; then
        setprop sys.usb.config adb
        log "Restored ADB mode"
      elif [ "$chkfrstfn" = "ffs.mtp" ]; then
        setprop sys.usb.config mtp
        log "Restored MTP mode"
      elif [ "$chkfrstfn" = "mtp.gs0" ]; then
        setprop sys.usb.config mtp
        log "Restored MTP mode (Samsung/Motorola variant)"
      fi
    fi
  fi
  sleep 0.5
done
