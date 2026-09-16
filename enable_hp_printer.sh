#!/bin/bash
modprobe libcomposite
cd /sys/kernel/config/usb_gadget/

# 1. Clean build directory
rm -rf hp_4001dn
mkdir -p hp_4001dn && cd hp_4001dn

# 2. Setup USB Identifiers
echo "0x03f0" > idVendor   
echo "0x0274" > idProduct  
echo "0x0100" > bcdDevice  
echo "0x0200" > bcdUSB     

echo "0x00" > bDeviceClass
echo "0x00" > bDeviceSubClass
echo "0x00" > bDeviceProtocol

# 3. Apply device strings
mkdir -p strings/0x409
echo "HP" > strings/0x409/manufacturer
echo "HP LaserJet Pro 4001dn" > strings/0x409/product
echo "PH12345678" > strings/0x409/serialnumber

# 4. Create paths and bind configuration FIRST
mkdir -p functions/printer.usb0
mkdir -p configs/c.1/strings/0x409
echo "Standard USB Printing" > configs/c.1/strings/0x409/configuration
ln -s functions/printer.usb0 configs/c.1/

# 5. Write the 1284ID descriptor NOW that the function is bound
echo "MFG:HP;MDL:LaserJet Pro 4001dn;CLS:PRINTER;DES:HP LaserJet Pro 4001dn;" > functions/printer.usb0/1284ID

# 6. Enable gadget over UDC
ls /sys/class/udc > UDC
echo "[+] HP LaserJet Pro 4001dn Gadget Loaded!"
