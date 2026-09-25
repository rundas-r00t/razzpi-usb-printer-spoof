#!/bin/bash
set -e

GADGET_NODE="/dev/g_printer0"
OUTDIR="/home/user/captured_jobs"
PDFDIR="/home/user/captured_pdfs"
LOGFILE="/home/user/capture.log"
JOB_TIMEOUT=5
CHUNK_SIZE=4096

mkdir -p "$OUTDIR" "$PDFDIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

convert_to_pdf() {
    local prn_file="$1"
    local base
    base=$(basename "$prn_file" .prn)
    local pdf_file="$PDFDIR/${base}.pdf"
    local tmp_dir
    tmp_dir=$(mktemp -d /tmp/ps_render_XXXXXX)

    log "Rasterizing $prn_file..."

    gs -dBATCH -dNOPAUSE \
       -sDEVICE=png16m \
       -r120 \
       -sOutputFile="${tmp_dir}/page_%04d.png" \
       "$prn_file" >> "$LOGFILE" 2>&1

    local page_count
    page_count=$(ls "${tmp_dir}"/page_*.png 2>/dev/null | wc -l)

    if [ "$page_count" -gt 0 ]; then
        log "$page_count pages rendered, assembling PDF..."
        convert "${tmp_dir}"/page_*.png "$pdf_file" >> "$LOGFILE" 2>&1
        if [ -s "$pdf_file" ]; then
            log "PDF saved: $pdf_file ($(du -h "$pdf_file" | cut -f1))"
        else
            log "WARNING: PDF assembly failed for $prn_file"
            rm -f "$pdf_file"
        fi
    else
        log "WARNING: No pages rendered from $prn_file"
    fi

    rm -rf "$tmp_dir"
}

log "=== Capture service started ==="
log "Waiting for $GADGET_NODE..."

while [ ! -e "$GADGET_NODE" ]; do
    sleep 2
done

log "$GADGET_NODE found. Setting printer status to READY..."

# Set printer status so Yocto knows we're ready to receive
python3 << 'STATUSEOF'
import fcntl, struct
GADGET_SET_PRINTER_STATUS = 0xc0016722
PRINTER_NOT_ERROR = 0x08
PRINTER_SELECTED  = 0x10
try:
    fd = open('/dev/g_printer0', 'r+b', buffering=0)
    fcntl.ioctl(fd, GADGET_SET_PRINTER_STATUS, struct.pack('B', PRINTER_NOT_ERROR | PRINTER_SELECTED))
    fd.close()
    print("Printer status set to READY (0x18)")
except Exception as e:
    print(f"Warning: could not set printer status: {e}")
STATUSEOF

log "Listening for print jobs..."

JOB_COUNT=1

while true; do
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    PRN_FILE="$OUTDIR/job_${TIMESTAMP}_${JOB_COUNT}.prn"

    python3 - <<PYEOF "$PRN_FILE" "$GADGET_NODE" "$JOB_TIMEOUT" "$CHUNK_SIZE"
import sys
import os
import time
import fcntl
import struct

outfile  = sys.argv[1]
devnode  = sys.argv[2]
timeout  = int(sys.argv[3])
chunk    = int(sys.argv[4])

fd = os.open(devnode, os.O_RDWR)

# Set printer status READY inside the read loop too
GADGET_SET_PRINTER_STATUS = 0xc0016722
try:
    fcntl.ioctl(fd, GADGET_SET_PRINTER_STATUS, struct.pack('B', 0x18))
    print("[py] Printer status: READY", flush=True)
except Exception as e:
    print(f"[py] Status warning: {e}", flush=True)

# Set non-blocking
flags = fcntl.fcntl(fd, fcntl.F_GETFL)
fcntl.fcntl(fd, fcntl.F_SETFL, flags | os.O_NONBLOCK)

total = 0
last_data = None
job_started = False

print(f"[py] Listening on {devnode}", flush=True)

MAX_SIZE = 50 * 1024 * 1024  # 50MB per file, then roll over

with open(outfile, 'wb') as f:
    while True:
        try:
            data = os.read(fd, chunk)
            if data:
                f.write(data)
                total += len(data)
                last_data = time.time()
                job_started = True
                print(f"[py] Read {len(data)} bytes (total: {total})", flush=True)
                if total >= MAX_SIZE:
                    print(f"[py] Size cap reached, rolling to next file", flush=True)
                    break
        except BlockingIOError:
            if job_started and last_data is not None:
                elapsed = time.time() - last_data
                if elapsed >= timeout:
                    print(f"[py] Job complete after {timeout}s silence. Total: {total} bytes", flush=True)
                    break
            elif not job_started:
                time.sleep(0.1)
                continue
            time.sleep(0.1)
        except Exception as e:
            print(f"[py] Error: {e}", flush=True)
            break

os.close(fd)
print(f"[py] Wrote {total} bytes to {outfile}", flush=True)
PYEOF

    if [ -s "$PRN_FILE" ]; then
        SIZE=$(wc -c < "$PRN_FILE")
        log "Job $JOB_COUNT captured: $PRN_FILE ($SIZE bytes)"
        convert_to_pdf "$PRN_FILE"
        JOB_COUNT=$((JOB_COUNT + 1))
    else
        rm -f "$PRN_FILE"
        sleep 1
    fi
done
