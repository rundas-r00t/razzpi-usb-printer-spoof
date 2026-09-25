#!/bin/bash
set -e
modprobe libcomposite
cd /sys/kernel/config/usb_gadget/

GADGET=hp_4001dn

# 1. Proper teardown if gadget already exists
if [ -d "$GADGET" ]; then
    echo "" > "$GADGET/UDC" 2>/dev/null || true
    rm -f "$GADGET"/configs/c.1/printer.usb0
    rmdir "$GADGET"/configs/c.1/strings/0x409 2>/dev/null || true
    rmdir "$GADGET"/configs/c.1 2>/dev/null || true
    rmdir "$GADGET"/functions/printer.usb0 2>/dev/null || true
    rmdir "$GADGET"/strings/0x409 2>/dev/null || true
    rmdir "$GADGET" 2>/dev/null || true
fi

mkdir -p "$GADGET" && cd "$GADGET"

# 2. USB identifiers
echo "0x03f0" > idVendor
echo "0x0274" > idProduct
echo "0x0100" > bcdDevice
echo "0x0200" > bcdUSB

# 3. Strings
mkdir -p strings/0x409
echo "HP, Inc" > strings/0x409/manufacturer
echo "HP LaserJet Pro 4001" > strings/0x409/product
echo "PH12345678" > strings/0x409/serialnumber

# 4. Printer function + PnP string (this is the field that carries the 1284 device ID on this kernel)
mkdir -p functions/printer.usb0
echo "MFG:HP;MDL:LaserJet Pro 4001dn;CLS:PRINTER;DES:HP LaserJet Pro 4001dn;" > functions/printer.usb0/pnp_string

# 5. Config + bind
mkdir -p configs/c.1/strings/0x409
echo "Standard USB Printing" > configs/c.1/strings/0x409/configuration
ln -s functions/printer.usb0 configs/c.1/

# 6. Bind to UDC last
ls /sys/class/udc > UDC
echo "[+] HP LaserJet Pro 4001dn Gadget Loaded!"
