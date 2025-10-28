if [ "$API" -lt '29' ]; then
  abort 'This module is for Android 10+ only'
fi

# Device detection
DEVICE_MODEL=$(getprop ro.product.device)
DEVICE_MANUFACTURER=$(getprop ro.product.manufacturer)
DEVICE_NAME=$(getprop ro.product.model)

# Log installation info
ui_print "----------------------------------------"
ui_print " DriveDroid Fix v2.0"
ui_print " Android $(getprop ro.build.version.release) (API $API)"
ui_print " Device: $DEVICE_MANUFACTURER $DEVICE_NAME"
ui_print "----------------------------------------"

# Check for Android 15 specific notes
if [ "$API" -ge '35' ]; then
  ui_print "Android 15 detected - Full support enabled"
  ui_print "Logs will be available at: /data/adb/fixdd.log"
elif [ "$API" -ge '33' ]; then
  ui_print "Android 13/14 detected - Full support"
else
  ui_print "Android 10/11/12 detected"
fi

# Motorola-specific messages
if [ "$DEVICE_MANUFACTURER" = "motorola" ] || [ "$DEVICE_MANUFACTURER" = "Motorola" ]; then
  ui_print ""
  ui_print "*** Motorola device detected ***"

  if [ "$DEVICE_MODEL" = "kansas" ]; then
    ui_print "Moto G 2025 (kansas) - Optimized support"
    ui_print "This device has been specifically configured"
  else
    ui_print "Model: $DEVICE_MODEL"
    ui_print "Motorola-specific optimizations enabled"
  fi

  ui_print ""
  ui_print "Important notes for Motorola:"
  ui_print "- Extended USB initialization time (15s)"
  ui_print "- Alternative USB gadget paths checked"
  ui_print "- Enhanced USB controller detection"
  ui_print "- Check logs if issues occur"
  ui_print ""
fi

ui_print "Installing service script..."
