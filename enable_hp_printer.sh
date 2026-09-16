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
echo "PH12345678" > strings/0x409/serialnumber
echo "HP" > strings/0x409/manufacturer
echo "HP LaserJet Pro 4001dn" > strings/0x409/product

# 4. Initialize printer framework & write descriptors (Using absolute path)
mkdir -p functions/printer.usb0
echo "MFG:HP;MDL:LaserJet Pro 4001dn;CLS:PRINTER;DES:HP LaserJet Pro 4001dn;" | sudo tee /sys/kernel/config/usb_gadget/hp_4001dn/functions/printer.usb0/1284ID > /dev/null


# 5. Bind configurations SECOND
mkdir -p configs/c.1/strings/0x409
echo "Standard USB Printing" > configs/c.1/strings/0x409/configuration
ln -s functions/printer.usb0 configs/c.1/

# 6. Enable gadget over UDC
ls /sys/class/udc > UDC
echo "[+] HP LaserJet Pro 4001dn Gadget Loaded!"

