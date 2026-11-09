"""
Synthetic fixture generator for Document Reviewer — Spike testing.
All files generated here are labeled SYNTHETIC and are used only for smoke tests.
They do NOT replace real-world fixtures for go/no-go decisions.

Python 3.14 stdlib only — no third-party dependencies.
"""

import zipfile
import struct
import io
import os
import math

BASE = r"D:\PDF_TOOL_APK\test\fixtures"
os.makedirs(BASE, exist_ok=True)

# ─────────────────────────────────────────────────────────────────────────────
# S1: synth_simple.pdf  — minimal valid 3-page PDF
# ─────────────────────────────────────────────────────────────────────────────
def make_pdf_page(content_stream: str, page_num: int) -> tuple[str, str, str]:
    """Returns (page_obj, content_obj, refs) as PDF object strings."""
    return content_stream, page_num

def make_simple_pdf(path: str, pages: list[str], title: str = "Synthetic Document"):
    """Build a minimal valid PDF with text content pages."""
    objects = []
    obj_offsets = []

    def add_obj(content: str) -> int:
        idx = len(objects) + 1
        objects.append(content)
        return idx

    # Build content streams
    page_content_ids = []
    page_ids = []
    for i, text in enumerate(pages):
        # Content stream
        stream = (
            f"BT\n"
            f"/F1 12 Tf\n"
            f"72 720 Td\n"
        )
        for j, line in enumerate(text.split('\n')):
            escaped = line.replace('(', r'\(').replace(')', r'\)')
            stream += f"({escaped}) Tj\n"
            if j < len(text.split('\n')) - 1:
                stream += "0 -18 Td\n"
        stream += "ET"

        stream_bytes = stream.encode('latin-1')
        content_id = add_obj(
            f"<< /Length {len(stream_bytes)} >>\nstream\n{stream}\nendstream"
        )
        page_content_ids.append(content_id)

        page_id = add_obj(
            f"<< /Type /Page /Parent 1 0 R "
            f"/MediaBox [0 0 612 792] "
            f"/Contents {content_id} 0 R "
            f"/Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> >>"
        )
        page_ids.append(page_id)

    # Pages dict (object 1 — placeholder, will insert at front)
    kids = " ".join(f"{pid} 0 R" for pid in page_ids)
    pages_obj = f"<< /Type /Pages /Kids [{kids}] /Count {len(pages)} >>"

    # Catalog (object 2)
    catalog_obj = "<< /Type /Catalog /Pages 1 0 R >>"

    # Reconstruct: insert pages_obj at idx 0, catalog at idx 1
    all_objects = [pages_obj, catalog_obj] + objects
    # page_ids and content_ids are offset by 2 now
    page_ids = [pid + 2 for pid in page_ids]
    page_content_ids = [cid + 2 for cid in page_content_ids]

    # Rebuild kids with corrected IDs
    kids = " ".join(f"{pid} 0 R" for pid in page_ids)
    all_objects[0] = f"<< /Type /Pages /Kids [{kids}] /Count {len(pages)} >>"

    # Re-fix page objects (they reference content IDs, also shifted by 2)
    new_objects = []
    for obj in all_objects:
        new_objects.append(obj)

    # Write PDF
    buf = io.BytesIO()
    buf.write(b"%PDF-1.4\n")
    offsets = []
    for i, obj_str in enumerate(all_objects):
        offsets.append(buf.tell())
        buf.write(f"{i+1} 0 obj\n{obj_str}\nendobj\n".encode('latin-1'))

    xref_offset = buf.tell()
    buf.write(b"xref\n")
    buf.write(f"0 {len(all_objects)+1}\n".encode())
    buf.write(b"0000000000 65535 f \n")
    for off in offsets:
        buf.write(f"{off:010d} 00000 n \n".encode())

    buf.write(
        f"trailer\n<< /Size {len(all_objects)+1} /Root 2 0 R >>\n"
        f"startxref\n{xref_offset}\n%%EOF\n".encode()
    )

    with open(path, 'wb') as f:
        f.write(buf.getvalue())
    print(f"  Created {os.path.basename(path)} ({buf.tell()} bytes)")


# ─────────────────────────────────────────────────────────────────────────────
# S2: synth_simple.docx — minimal valid DOCX (OpenXML ZIP)
# ─────────────────────────────────────────────────────────────────────────────
def make_simple_docx(path: str, paragraphs: list[str], title: str = "Synthetic DOCX"):
    CONTENT_TYPES = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml"
    ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>'''

    RELS = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1"
    Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"
    Target="word/document.xml"/>
</Relationships>'''

    WORD_RELS = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
</Relationships>'''

    # Build document body
    para_xml = ""
    for text in paragraphs:
        escaped = (text.replace('&', '&amp;').replace('<', '&lt;')
                   .replace('>', '&gt;').replace('"', '&quot;'))
        para_xml += f'''  <w:p><w:r><w:t xml:space="preserve">{escaped}</w:t></w:r></w:p>\n'''

    DOCUMENT = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
{para_xml}  <w:sectPr/>
  </w:body>
</w:document>'''

    with zipfile.ZipFile(path, 'w', compression=zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml', CONTENT_TYPES)
        z.writestr('_rels/.rels', RELS)
        z.writestr('word/_rels/document.xml.rels', WORD_RELS)
        z.writestr('word/document.xml', DOCUMENT)
    sz = os.path.getsize(path)
    print(f"  Created {os.path.basename(path)} ({sz} bytes)")


# ─────────────────────────────────────────────────────────────────────────────
# S3: synth_simple.xlsx — minimal valid XLSX (OpenXML ZIP)
# ─────────────────────────────────────────────────────────────────────────────
def make_simple_xlsx(path: str, data: list[list], sheet_name: str = "Sheet1"):
    CONTENT_TYPES = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml"
    ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml"
    ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
</Types>'''

    RELS = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1"
    Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"
    Target="xl/workbook.xml"/>
</Relationships>'''

    WORKBOOK_RELS = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1"
    Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"
    Target="worksheets/sheet1.xml"/>
</Relationships>'''

    WORKBOOK = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="{sheet_name}" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>'''

    def col_letter(n):
        result = ''
        while n > 0:
            n, rem = divmod(n - 1, 26)
            result = chr(65 + rem) + result
        return result

    rows_xml = ''
    for r_idx, row in enumerate(data, 1):
        cells = ''
        for c_idx, val in enumerate(row, 1):
            cell_ref = f"{col_letter(c_idx)}{r_idx}"
            if isinstance(val, (int, float)):
                cells += f'<c r="{cell_ref}"><v>{val}</v></c>'
            else:
                escaped = str(val).replace('&', '&amp;').replace('<', '&lt;')
                cells += f'<c r="{cell_ref}" t="inlineStr"><is><t>{escaped}</t></is></c>'
        rows_xml += f'<row r="{r_idx}">{cells}</row>\n'

    SHEET = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>
{rows_xml}  </sheetData>
</worksheet>'''

    with zipfile.ZipFile(path, 'w', compression=zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml', CONTENT_TYPES)
        z.writestr('_rels/.rels', RELS)
        z.writestr('xl/_rels/workbook.xml.rels', WORKBOOK_RELS)
        z.writestr('xl/workbook.xml', WORKBOOK)
        z.writestr('xl/worksheets/sheet1.xml', SHEET)
    sz = os.path.getsize(path)
    print(f"  Created {os.path.basename(path)} ({sz} bytes)")


# ─────────────────────────────────────────────────────────────────────────────
# S4: synth_corrupted.pdf — valid PDF truncated at 90%
# ─────────────────────────────────────────────────────────────────────────────
def make_corrupted_pdf(path: str, source_path: str):
    with open(source_path, 'rb') as f:
        data = f.read()
    truncated = data[:int(len(data) * 0.88)]  # remove last 12%
    with open(path, 'wb') as f:
        f.write(truncated)
    print(f"  Created {os.path.basename(path)} ({len(truncated)} bytes, truncated from {len(data)})")


# ─────────────────────────────────────────────────────────────────────────────
# S5/S6/S7: BMP images (no PIL needed — write raw BMP)
# ─────────────────────────────────────────────────────────────────────────────
def make_bmp(path: str, width: int, height: int,
             text_lines: list[str] = None, bg=(255,255,255), fg=(0,0,0),
             rotate_deg: float = 0):
    """Create a minimal BMP file with simple text rendering (8x8 bitmap font)."""
    # Simple 8x8 font for ASCII 32-127
    # We'll just draw horizontal lines as a placeholder for "text"
    pixels = [list(bg) for _ in range(width * height)]

    def set_pixel(x, y, color):
        if 0 <= x < width and 0 <= y < height:
            pixels[y * width + x] = list(color)

    def draw_rect(x1, y1, x2, y2, color):
        for x in range(max(0,x1), min(width, x2)):
            for y in range(max(0,y1), min(height, y2)):
                set_pixel(x, y, color)

    # Draw simple text representation as dark lines on white background
    if text_lines:
        y_pos = 20
        for line in text_lines:
            # Draw a horizontal bar to represent each line of text
            bar_width = min(len(line) * 7, width - 40)
            draw_rect(20, y_pos, 20 + bar_width, y_pos + 8, fg)
            y_pos += 18
            if y_pos > height - 20:
                break

    # Draw document border
    for x in range(width):
        set_pixel(x, 10, (180, 180, 180))
        set_pixel(x, height - 10, (180, 180, 180))
    for y in range(height):
        set_pixel(10, y, (180, 180, 180))
        set_pixel(width - 10, y, (180, 180, 180))

    # Simple rotation simulation: skew the image slightly
    if rotate_deg != 0:
        rad = math.radians(rotate_deg)
        cx, cy = width // 2, height // 2
        rotated = [list(bg) for _ in range(width * height)]
        for y in range(height):
            for x in range(width):
                # Inverse rotation
                dx, dy = x - cx, y - cy
                src_x = int(dx * math.cos(-rad) - dy * math.sin(-rad) + cx)
                src_y = int(dx * math.sin(-rad) + dy * math.cos(-rad) + cy)
                if 0 <= src_x < width and 0 <= src_y < height:
                    rotated[y * width + x] = pixels[src_y * width + src_x]
        pixels = rotated

    # BMP file format
    row_size = (width * 3 + 3) & ~3  # 4-byte aligned
    pixel_data_size = row_size * height
    file_size = 54 + pixel_data_size

    buf = io.BytesIO()
    # File header
    buf.write(b'BM')
    buf.write(struct.pack('<I', file_size))
    buf.write(struct.pack('<HH', 0, 0))
    buf.write(struct.pack('<I', 54))
    # DIB header
    buf.write(struct.pack('<I', 40))       # header size
    buf.write(struct.pack('<i', width))
    buf.write(struct.pack('<i', -height))  # negative = top-down
    buf.write(struct.pack('<H', 1))        # color planes
    buf.write(struct.pack('<H', 24))       # bits per pixel
    buf.write(struct.pack('<I', 0))        # no compression
    buf.write(struct.pack('<I', pixel_data_size))
    buf.write(struct.pack('<i', 2835))     # pixels per meter X
    buf.write(struct.pack('<i', 2835))     # pixels per meter Y
    buf.write(struct.pack('<I', 0))
    buf.write(struct.pack('<I', 0))

    # Pixel data (BGR for BMP)
    for y in range(height):
        row = b''
        for x in range(width):
            r, g, b = pixels[y * width + x]
            row += struct.pack('BBB', b, g, r)
        # Pad row to 4-byte boundary
        pad = row_size - width * 3
        row += b'\x00' * pad
        buf.write(row)

    with open(path, 'wb') as f:
        f.write(buf.getvalue())
    sz = os.path.getsize(path)
    print(f"  Created {os.path.basename(path)} ({sz//1024} KB)")


# ─────────────────────────────────────────────────────────────────────────────
# MAIN — Generate all synthetic fixtures
# ─────────────────────────────────────────────────────────────────────────────
print("Generating synthetic test fixtures...")
print("Label: 🔬 SINTETIS — for smoke tests only, not go/no-go decisions\n")

# S1: simple PDF (3 pages)
print("[S1] synth_simple.pdf")
make_simple_pdf(
    os.path.join(BASE, "synth_simple.pdf"),
    pages=[
        "Page 1 - Document Reviewer Synthetic Test\nThis is a synthetic PDF fixture.\nCreated for smoke testing only.\nLabel: SINTETIS",
        "Page 2 - Halaman Kedua\nIni adalah halaman kedua dari dokumen sintetis.\nDigunakan untuk pengujian dasar.",
        "Page 3 - Final Page\nEnd of synthetic document.\nAll content is placeholder text."
    ]
)

# S2: simple DOCX (2 paragraphs)
print("[S2] synth_simple.docx")
make_simple_docx(
    os.path.join(BASE, "synth_simple.docx"),
    paragraphs=[
        "SINTETIS - Document Reviewer Test Fixture",
        "Ini adalah dokumen DOCX sintetis untuk pengujian integrasi Apache POI.",
        "Paragraph ketiga dengan konten tambahan untuk validasi struktur XML.",
        "Fourth paragraph - testing multi-paragraph DOCX parsing.",
        "Fifth paragraph - end of synthetic document content.",
    ]
)

# S3: simple XLSX (header + 10 rows of data)
print("[S3] synth_simple.xlsx")
data = [
    ["No", "Nama", "Nilai", "Status"],
]
for i in range(1, 11):
    data.append([i, f"Item {i}", i * 10.5, "AKTIF" if i % 2 == 0 else "NONAKTIF"])
make_simple_xlsx(os.path.join(BASE, "synth_simple.xlsx"), data)

# S4: corrupted PDF
print("[S4] synth_corrupted.pdf")
make_corrupted_pdf(
    os.path.join(BASE, "synth_corrupted.pdf"),
    os.path.join(BASE, "synth_simple.pdf")
)

# S5: clean scan (white background, dark text bars)
print("[S5] synth_scan_clean.bmp")
make_bmp(
    os.path.join(BASE, "synth_scan_clean.bmp"), 800, 1100,
    text_lines=[
        "DOKUMEN REVIEWER - PENGUJIAN OCR",
        "Baris pertama teks cetak bersih.",
        "Baris kedua: angka 1234567890",
        "Baris ketiga: dokumen Indonesia.",
        "Line four: English mixed content.",
        "Baris lima: akhir dokumen sintetis.",
    ]
)

# S6: skewed scan (~25 degrees)
print("[S6] synth_scan_skewed.bmp")
make_bmp(
    os.path.join(BASE, "synth_scan_skewed.bmp"), 800, 1100,
    text_lines=[
        "DOKUMEN REVIEWER - PENGUJIAN MIRING",
        "Teks ini dirotasi 25 derajat.",
        "Skewed text for edge detection test.",
        "Baris keempat teks miring.",
    ],
    rotate_deg=25.0
)

# S7: Indonesian text simulation
print("[S7] synth_ocr_id.bmp")
make_bmp(
    os.path.join(BASE, "synth_ocr_id.bmp"), 800, 600,
    text_lines=[
        "REPUBLIK INDONESIA",
        "Nomor Induk Kependudukan:",
        "Nama: DOKUMEN REVIEWER",
        "Tempat/Tgl Lahir: Jakarta, 01-01-2024",
        "Jenis Kelamin: -",
        "Alamat: Jl. Flutter No. 1",
        "RT/RW: 001/001",
        "Kel/Desa: Kode",
        "Kecamatan: Riverpod",
        "Agama: -",
        "Status Perkawinan: -",
        "Pekerjaan: Software Engineer",
        "Kewarganegaraan: WNI",
    ]
)

print("\n✅ All synthetic fixtures generated.")
print(f"Location: {BASE}")
print("\nFiles created:")
for f in sorted(os.listdir(BASE)):
    if not f.startswith('.'):
        fpath = os.path.join(BASE, f)
        if os.path.isfile(fpath):
            sz = os.path.getsize(fpath)
            tag = "🔬 SINTETIS" if f.startswith("synth_") else "📄"
            print(f"  {tag}  {f} ({sz:,} bytes)")

