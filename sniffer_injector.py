import os
import sys

GADGET_NODE = '/dev/g_printer0'

if not os.path.exists(GADGET_NODE):
    print(f"[-] Error: {GADGET_NODE} not found. Did you run the setup script?")
    sys.exit(1)

print("[+] Sniffer active. Awaiting laptop connection...")

with open(GADGET_NODE, 'r+b', buffering=0) as usb_bus:
    while True:
        try:
            packet = usb_bus.read(4096)
            if packet:
                print(f"\n[PACKET CAPTURED - {len(packet)} bytes]")
                try:
                    print(packet.decode('utf-8', errors='replace')[:500])
                except Exception:
                    print(packet[:100])

                # Auto-respond to handshake queries to keep laptop from erroring out
                if b"@PJL INFO STATUS" in packet:
                    print("[->] Sending spoofed READY status.")
                    usb_bus.write(b'\x1b%-12345X@PJL INFO STATUS\r\nCODE=10001\r\nDISPLAY="READY"\r\n\x1b%-12345X')
                elif b"GET_DEVICE_ID" in packet:
                    print("[->] Sending Device ID string.")
                    usb_bus.write(b"MFG:HP;MDL:LaserJet Pro 4001dn;CLS:PRINTER;CMD:PCL6;DES:HP LaserJet Pro 4001dn;")
                else:
                    usb_bus.write(b"\x00") 
        except KeyboardInterrupt:
            print("\n[-] Exiting.")
            break
        except Exception as e:
            print(f"[-] Bus Warning: {e}")
            continue
