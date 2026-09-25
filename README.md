# razzpi-usb-printer-spoof

step 1 

set up your razzpi with proper wifi & ssh creds

step 2

ssh into the razz and copy/paste the two scripts via nano and save and chmod +x both. be sure to `mkdir captured_jobs` as output will live there. copy the hp-gadget.service file to `/etc/systemd/system` on the razz and then `sudo systemctl daemon-reload` to have the bash script run at start-up.

you will likely need to take your attack laptop and plug it into the printer you want to spoof and use `lsusb` to grab the proper manufacturer name and ID. update the enable_hp_printer.sh script accordingly. 

step 3

plug the razzpi into the victim laptop/print server & ensure it turns on properly. after booting, it should now be spoofing the printer.

step 4 

~~ssh into the razzPi again and `python3 sniffer_injector.py`~~ this is still a work in progress

print jobs will go to the pi and be saved in the  `/captured_jobs/` folder. then, the Pi will automatically convert the *.prn files to .pdf's and save them to the `/captured_pdfs/` folder for later retrieval & inspection via `scp`.






> note: apparently it is not possible to pop a shell via printer USB spoofing, as this type of code execution was mitigated in 2021. you'd have to have a vulnerable driver in place on the victim PC/print server in order to have success with that type of attack.
