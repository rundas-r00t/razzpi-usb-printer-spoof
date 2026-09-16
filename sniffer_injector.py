import os
import sys
import time

GADGET_NODE = '/dev/g_printer0'
OUTPUT_DIR = './captured_jobs'

# Ensure the capture directory exists on the Pi
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

if not os.path.exists(GADGET_NODE):
    print(f"[-] Error: {GADGET_NODE} not found. Did you run the setup script?")
    sys.exit(1)

print("[+] Sniffer active. Saving print jobs locally on the Pi...")
print(f"[+] Output directory: {os.path.abspath(OUTPUT_DIR)}")

current_job_file = None

with open(GADGET_NODE, 'r+b', buffering=0) as usb_bus:
    while True:
        try:
            packet = usb_bus.read(4096)
            if packet:
                # If we detect a standard print language initialization header, open a new file
                if b"\x1b%-12345X" in packet or b"@PJL" in packet:
                    if current_job_file:
                        current_job_file.close()
                    
                    timestamp = time.strftime("%Y%m%d-%H%M%S")
                    filename = os.path.join(OUTPUT_DIR, f"job_{timestamp}.prn")
                    print(f"\n[+] New Print Job Detected! Saving to: {filename}")
                    current_job_file = open(filename, 'wb')

                # Write the raw chunk to our local file on the Pi if a job is active
                if current_job_file:
                    current_job_file.write(packet)
                    current_job_file.flush()

                # Handle standard responses to keep the laptop happy
                if b"@PJL INFO STATUS" in packet:
                    usb_bus.write(b'\x1b%-12345X@PJL INFO STATUS\r\nCODE=10001\r\nDISPLAY="READY"\r\n\x1b%-12345X')
                elif b"GET_DEVICE_ID" in packet:
                    usb_bus.write(b"MFG:HP;MDL:LaserJet Pro 4001dn;CLS:PRINTER;CMD:PCL6;DES:HP LaserJet Pro 4001dn;")
                else:
                    usb_bus.write(b"\x00") 
                    
        except KeyboardInterrupt:
            if current_job_file:
                current_job_file.close()
            print("\n[-] Exiting Sniffer.")
            break
        except Exception as e:
            print(f"[-] Bus Warning: {e}")
            continue
