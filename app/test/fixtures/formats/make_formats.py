#!/usr/bin/env python3
"""Makes one small sample book per file format, for the engine test.

Usage: python3 make_formats.py [output folder]

The text is written for this test. Python writes the simple formats
(TXT, HTML, Markdown, FB3, MOBI, PalmDoc PDB, TCR and the zipped forms).
LibreOffice (soffice) converts the HTML file to RTF, DOC, DOCX and ODT; without
it those four files are not made. A CHM file cannot be made here, and there
is none in the repository (see the Tests section of the README).
"""
import os
import shutil
import struct
import subprocess
import sys
import zipfile

TITLE = "Format Sample"
AUTHOR = "Test Author"
CHAPTERS = 3
PARAGRAPHS = 14

SENTENCES = [
    "The reader opens this file to check one file format.",
    "Each chapter holds the same plain sentences, so that the book has more than one page.",
    "A page turn moves to the next part of the text, and the position is kept when the book closes.",
    "The table of contents lists three chapters when the format can carry one.",
    "Nothing in this text is taken from a published book.",
]


def paragraph(chapter, number):
    return "Chapter %d, paragraph %d. %s" % (chapter, number, " ".join(SENTENCES))


def chapters():
    for c in range(1, CHAPTERS + 1):
        yield c, [paragraph(c, n) for n in range(1, PARAGRAPHS + 1)]


def plain_text():
    out = [TITLE, AUTHOR, ""]
    for c, paragraphs in chapters():
        out += ["Chapter %d" % c, ""]
        for p in paragraphs:
            out += [p, ""]
    return "\n".join(out)


def html(xhtml=False):
    head = '<html xmlns="http://www.w3.org/1999/xhtml">' if xhtml else "<html>"
    out = [head, "<head>", '<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>',
           "<title>%s</title>" % TITLE, '<meta name="author" content="%s"/>' % AUTHOR, "</head>", "<body>"]
    for c, paragraphs in chapters():
        out.append("<h1>Chapter %d</h1>" % c)
        out += ["<p>%s</p>" % p for p in paragraphs]
    out += ["</body>", "</html>"]
    text = "\n".join(out)
    return ('<?xml version="1.0" encoding="utf-8"?>\n' + text) if xhtml else text


def markdown():
    out = ["# %s" % TITLE, "", AUTHOR, ""]
    for c, paragraphs in chapters():
        out += ["## Chapter %d" % c, ""]
        for p in paragraphs:
            out += [p, ""]
    return "\n".join(out)


def zipped(path, name, data):
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr(name, data)


def fb3(path):
    types = """<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/fb3/description.xml" ContentType="application/fb3-description+xml"/>
<Override PartName="/fb3/body.xml" ContentType="application/fb3-body+xml"/>
<Override PartName="/fb3/meta/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
</Types>"""
    rels = """<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId0" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="fb3/meta/core.xml"/>
<Relationship Id="rId1" Type="http://www.fictionbook.org/FictionBook3/relationships/Book" Target="fb3/description.xml"/>
</Relationships>"""
    desc_rels = """<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId0" Type="http://www.fictionbook.org/FictionBook3/relationships/body" Target="body.xml"/>
</Relationships>"""
    core = """<?xml version="1.0" encoding="UTF-8"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/">
<dc:title>%s</dc:title><dc:creator>%s</dc:creator><dc:language>en</dc:language>
</cp:coreProperties>""" % (TITLE, AUTHOR)
    description = """<?xml version="1.0" encoding="UTF-8"?>
<fb3-description xmlns="http://www.fictionbook.org/FictionBook3/description" id="00000000-0000-4000-8000-000000000001" version="1.0">
<title><main>%s</main></title>
<fb3-relations><subject link="author" id="00000000-0000-4000-8000-000000000002"><title><main>%s</main></title><first-name>Test</first-name><last-name>Author</last-name></subject></fb3-relations>
<lang>en</lang>
<document-info created="2026-11-15T00:00:00" updated="2026-11-15T00:00:00"/>
</fb3-description>""" % (TITLE, AUTHOR)
    body = ['<?xml version="1.0" encoding="UTF-8"?>',
            '<fb3-body xmlns="http://www.fictionbook.org/FictionBook3/body" id="00000000-0000-4000-8000-000000000003">',
            "<title><p>%s</p></title>" % TITLE]
    for c, paragraphs in chapters():
        body.append('<section id="00000000-0000-4000-8000-0000000001%02d"><title><p>Chapter %d</p></title>' % (c, c))
        body += ["<p>%s</p>" % p for p in paragraphs]
        body.append("</section>")
    body.append("</fb3-body>")
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", types)
        z.writestr("_rels/.rels", rels)
        z.writestr("fb3/_rels/description.xml.rels", desc_rels)
        z.writestr("fb3/meta/core.xml", core)
        z.writestr("fb3/description.xml", description)
        z.writestr("fb3/body.xml", "\n".join(body))


def pdb_file(path, name, kind, creator, records):
    """A Palm database: 78 byte header, record list, 2 pad bytes, records."""
    count = len(records)
    offset = 78 + 8 * count + 2
    header = struct.pack(">32sHHIIIIII4s4sIIH", name.encode("ascii")[:31], 0, 0, 0, 0, 0, 0, 0, 0,
                         kind, creator, 2 * count - 1, 0, count)
    entries = b""
    for i, r in enumerate(records):
        entries += struct.pack(">IB3s", offset, 0, struct.pack(">I", 2 * i)[1:])
        offset += len(r)
    with open(path, "wb") as f:
        f.write(header + entries + b"\0\0" + b"".join(records))


def split(data, size=4096):
    return [data[i:i + size] for i in range(0, len(data), size)]


def palmdoc(path):
    """PalmDoc text, not compressed."""
    data = plain_text().encode("cp1252")
    parts = split(data)
    record0 = struct.pack(">HHIHHI", 1, 0, len(data), len(parts), 4096, 0)
    pdb_file(path, "Format_Sample", b"TEXt", b"REAd", [record0] + parts)


def mobi(path):
    """Mobipocket book (the old form, version 6), not compressed, no DRM."""
    data = html().encode("utf-8")
    parts = split(data)
    name = TITLE.encode("utf-8")
    header_length = 232
    palmdoc = struct.pack(">HHIHHHH", 1, 0, len(data), len(parts), 4096, 0, 0)
    mobi_header = bytearray(b"\0" * header_length)
    struct.pack_into(">4sIIIII", mobi_header, 0, b"MOBI", header_length, 2, 65001, 0x1234ABCD, 6)
    for i in range(10):  # reserved: all 0xFF
        struct.pack_into(">I", mobi_header, 24 + 4 * i, 0xFFFFFFFF)
    struct.pack_into(">IIIIIIIIII", mobi_header, 64,
                     len(parts) + 1,          # first record that is not text
                     16 + header_length,      # full name offset in record 0
                     len(name),
                     1033, 0, 0, 6,           # locale, dictionary languages, min version
                     0xFFFFFFFF,              # first image record: none
                     0, 0)                    # no huffman records
    struct.pack_into(">I", mobi_header, 112, 0)  # EXTH flags: no EXTH record
    struct.pack_into(">IIII", mobi_header, 148, 0xFFFFFFFF, 0xFFFFFFFF, 0, 0)  # no DRM
    record0 = palmdoc + bytes(mobi_header) + name + b"\0\0"
    record0 += b"\0" * (-len(record0) % 4)
    pdb_file(path, "Format_Sample", b"BOOK", b"MOBI", [record0] + parts)


def tcr(path):
    """TCR text: a 256 entry dictionary, then one code per byte."""
    data = plain_text().encode("cp1252")
    out = bytearray(b"!!8-Bit!!")
    for code in range(256):
        out += bytes([1, code])
    out += data
    with open(path, "wb") as f:
        f.write(out)


def office(folder, source):
    soffice = shutil.which("soffice")
    if not soffice:
        print("soffice not found: RTF, DOC, DOCX and ODT are not made")
        return
    filters = {"odt": "odt:writer8", "docx": "docx:MS Word 2007 XML", "doc": "doc:MS Word 97", "rtf": "rtf:Rich Text Format"}
    for ext, name in filters.items():
        subprocess.run([soffice, "--headless", "--infilter=HTML (StarWriter)", "--convert-to", name,
                        "--outdir", folder, source], check=True, stdout=subprocess.DEVNULL)


def main():
    folder = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(__file__))
    os.makedirs(folder, exist_ok=True)

    def write(name, text):
        with open(os.path.join(folder, name), "w", encoding="utf-8", newline="\n") as f:
            f.write(text)

    write("sample.txt", plain_text())
    write("sample.html", html())
    write("sample.htm", html())
    write("sample.xhtml", html(xhtml=True))
    write("sample.md", markdown())
    zipped(os.path.join(folder, "sample.txt.zip"), "sample.txt", plain_text())
    zipped(os.path.join(folder, "sample.html.zip"), "sample.html", html())
    zipped(os.path.join(folder, "sample.htm.zip"), "sample.htm", html())
    zipped(os.path.join(folder, "sample.htmlz"), "index.html", html())
    # Other names of the EPUB and FB2 samples that are in the folder above.
    above = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    fb2 = os.path.join(above, "sample.fb2")
    if os.path.exists(fb2):
        with open(fb2, "rb") as f:
            data = f.read()
        zipped(os.path.join(folder, "sample.fb2.zip"), "sample.fb2", data)
        zipped(os.path.join(folder, "sample.fbz"), "sample.fb2", data)
    epub = os.path.join(above, "leaves.epub")
    if os.path.exists(epub):
        shutil.copyfile(epub, os.path.join(folder, "sample.epub3"))
    fb3(os.path.join(folder, "sample.fb3"))
    palmdoc(os.path.join(folder, "sample.pdb"))
    mobi(os.path.join(folder, "sample.mobi"))
    shutil.copyfile(os.path.join(folder, "sample.mobi"), os.path.join(folder, "sample.azw"))
    shutil.copyfile(os.path.join(folder, "sample.mobi"), os.path.join(folder, "sample.prc"))
    tcr(os.path.join(folder, "sample.tcr"))
    office(folder, os.path.join(folder, "sample.html"))
    rtf = os.path.join(folder, "sample.rtf")
    if os.path.exists(rtf):
        with open(rtf, "rb") as f:
            zipped(os.path.join(folder, "sample.rtf.zip"), "sample.rtf", f.read())
    docx = os.path.join(folder, "sample.docx")
    if os.path.exists(docx):
        shutil.copyfile(docx, os.path.join(folder, "sample.docm"))


if __name__ == "__main__":
    main()
