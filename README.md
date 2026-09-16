# razzpi-usb-printer-spoof

step 1 

set up your razzpi with proper wifi & ssh creds

step 2

ssh into the razz and copy/paste the two scripts via nano and save and chmod +x both. you will likely need to take your attack laptop and plug it into the printer you want to spoof and use `lsusb` to grab the proper manufacturer name and ID. update the enable...sh script accordingly

step 3

plug the razzpi into the victim laptop/print server & ensure it turns on properly. after booting, it should now be spoofing the printer.

step 4 

print jobs will go to the pi & the pi should try to pop a shell (work in progress on this currently)
