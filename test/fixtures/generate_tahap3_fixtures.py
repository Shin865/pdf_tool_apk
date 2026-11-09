"""
Generate Tahap 3 synthetic fixtures for Document Reviewer:
- synth_simple.txt: Plain text with Indonesian and English lines
- synth_simple.csv: CSV with headers and rows
- synth_sample.png: Minimal valid PNG image
- synth_sample.jpg: Minimal valid JPEG image
- synth_500pages.pdf: 500-page valid synthetic PDF for low-RAM stress testing
- synth_large.csv: Large CSV (multi-megabytes/thousands of rows) for lazy loading test
"""

import os
import io
import struct
import zlib

BASE = r"D:\PDF_TOOL_APK\test\fixtures"
os.makedirs(BASE, exist_ok=True)

# 1. Plain text file
txt_path = os.path.join(BASE, "synth_simple.txt")
with open(txt_path, "w", encoding="utf-8") as f:
    f.write("DOKUMEN REVIEWER - TAHAP 3 PENGUJIAN TEKS\n")
    f.write("Aplikasi pembaca dan pengulas dokumen offline untuk Android.\n")
    f.write("Line 3: Universal Android Compatibility minSdk 26.\n")
    f.write("Line 4: Dukungan berkas teks besar dengan pembacaan berbasis chunk.\n")
    f.write("Line 5: Baris terakhir berkas teks pengujian.\n")
print(f"[TXT] Created {txt_path}")

# 2. CSV file
csv_path = os.path.join(BASE, "synth_simple.csv")
with open(csv_path, "w", encoding="utf-8") as f:
    f.write("ID,Nama,Format,Ukuran,Status\n")
    f.write("1,Dokumen Proyek.pdf,PDF,204800,Aktif\n")
    f.write("2,Laporan Keuangan.xlsx,Spreadsheet,102400,Selesai\n")
    f.write("3,Proposal Riset.docx,Word,51200,Draft\n")
    f.write("4,Bagan Alir.png,Gambar,153600,Reviu\n")
    f.write("5,Catatan Rapat.txt,Teks,4096,Arsip\n")
print(f"[CSV] Created {csv_path}")

# 3. Minimal valid 1x1 PNG image
png_path = os.path.join(BASE, "synth_sample.png")
png_signature = b'\x89PNG\r\n\x1a\n'
def chunk(chunk_type, data):
    crc = zlib.crc32(chunk_type + data) & 0xffffffff
    return struct.pack('>I', len(data)) + chunk_type + data + struct.pack('>I', crc)

ihdr = struct.pack('>IIBBBBB', 2, 2, 8, 2, 0, 0, 0) # 2x2 RGB image
raw_pixels = b'\x00\xff\x00\x00\x00\xff\x00\x00\x00\x00\xff\xff\xff\x00' # scanlines with filter byte 0
idat = zlib.compress(raw_pixels)

with open(png_path, "wb") as f:
    f.write(png_signature)
    f.write(chunk(b'IHDR', ihdr))
    f.write(chunk(b'IDAT', idat))
    f.write(chunk(b'IEND', b''))
print(f"[PNG] Created {png_path}")

# 4. Minimal valid JPEG image
jpg_path = os.path.join(BASE, "synth_sample.jpg")
# Minimal 1x1 valid JFIF JPEG
jpeg_bytes = bytes([
    0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
    0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
    0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
    0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
    0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
    0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
    0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
    0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
    0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00,
    0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
    0x09, 0x0A, 0x0B, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F,
    0x00, 0xBF, 0x00, 0xFF, 0xD9
])
with open(jpg_path, "wb") as f:
    f.write(jpeg_bytes)
print(f"[JPG] Created {jpg_path}")

# 5. Synthetic 500-Page PDF
pdf500_path = os.path.join(BASE, "synth_500pages.pdf")
def make_500page_pdf(target_path: str, count: int = 500):
    buf = io.BytesIO()
    buf.write(b"%PDF-1.4\n")
    offsets = []
    
    # We will have:
    # Obj 1: Pages catalog
    # Obj 2: Catalog
    # Obj 3: Font resource
    # For each page i (1..count):
    #   Obj (4 + 2*(i-1)): Page
    #   Obj (5 + 2*(i-1)): Content stream
    
    font_id = 3
    page_ids = []
    total_objects = 3 + count * 2
    
    # Placeholders for offset table
    # We will assemble all objects as byte blocks
    objects_data = {}
    
    # Font
    objects_data[font_id] = b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"
    
    for i in range(1, count + 1):
        pid = 4 + 2 * (i - 1)
        cid = pid + 1
        page_ids.append(pid)
        
        stream_text = f"BT /F1 14 Tf 72 720 Td (Document Reviewer - Page {i} of {count}) Tj ET\n"
        stream_bytes = stream_text.encode('ascii')
        objects_data[cid] = f"<< /Length {len(stream_bytes)} >>\nstream\n".encode('ascii') + stream_bytes + b"endstream"
        objects_data[pid] = (
            f"<< /Type /Page /Parent 1 0 R /MediaBox [0 0 612 792] "
            f"/Contents {cid} 0 R /Resources << /Font << /F1 {font_id} 0 R >> >> >>"
        ).encode('ascii')
        
    kids_str = " ".join(f"{pid} 0 R" for pid in page_ids)
    objects_data[1] = f"<< /Type /Pages /Kids [{kids_str}] /Count {count} >>".encode('ascii')
    objects_data[2] = b"<< /Type /Catalog /Pages 1 0 R >>"
    
    obj_offsets = [0] * (total_objects + 1)
    
    for oid in range(1, total_objects + 1):
        obj_offsets[oid] = buf.tell()
        data = objects_data[oid]
        buf.write(f"{oid} 0 obj\n".encode('ascii'))
        buf.write(data)
        buf.write(b"\nendobj\n")
        
    xref_pos = buf.tell()
    buf.write(f"xref\n0 {total_objects + 1}\n".encode('ascii'))
    buf.write(b"0000000000 65535 f \n")
    for oid in range(1, total_objects + 1):
        buf.write(f"{obj_offsets[oid]:010d} 00000 n \n".encode('ascii'))
        
    trailer = f"trailer\n<< /Size {total_objects + 1} /Root 2 0 R >>\nstartxref\n{xref_pos}\n%%EOF\n"
    buf.write(trailer.encode('ascii'))
    
    with open(target_path, "wb") as f:
        f.write(buf.getvalue())
        
make_500page_pdf(pdf500_path, 500)
sz500 = os.path.getsize(pdf500_path)
print(f"[PDF-500] Created {pdf500_path} ({sz500:,} bytes)")

# 6. Large CSV file (50,000 rows with Indonesian text)
large_csv_path = os.path.join(BASE, "synth_large.csv")
with open(large_csv_path, "w", encoding="utf-8") as f:
    f.write("TransactionID,Tanggal,NamaNasabah,Kategori,Nominal,Status,Keterangan\n")
    for i in range(1, 50001):
        f.write(f"TRX{i:07d},2024-11-{(i%28)+1:02d},Nasabah_{i},Pembayaran,{10000 + (i*150)},Berhasil,Transaksi otomatis sistem review\n")
sz_csv = os.path.getsize(large_csv_path)
print(f"[CSV-Large] Created {large_csv_path} ({sz_csv:,} bytes, 50,000 rows)")

print("\nAll Tahap 3 synthetic fixtures successfully created.")

