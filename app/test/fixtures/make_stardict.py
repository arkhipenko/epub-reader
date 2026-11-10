#!/usr/bin/env python3
"""Builds the small StarDict test dictionaries in test/fixtures/dict.

Run from app/:  python3 test/fixtures/make_stardict.py

dict_a: sametypesequence=m, articles in dictzip (.dict.dz) with a tiny chunk
        size, so that articles cross chunk boundaries; synonyms (.syn).
dict_b: sametypesequence=h (HTML), plain .dict.
"""
import os
import struct
import zlib

OUT = os.path.join(os.path.dirname(__file__), 'dict')


def sort_key(word):
    b = word.encode('utf-8')
    return (bytes(c + 32 if 65 <= c <= 90 else c for c in b), b)


def write_dict(name, bookname, entries, typeseq, dictzip=False, synonyms=None, chunk=20):
    os.makedirs(OUT, exist_ok=True)
    base = os.path.join(OUT, name)
    entries = sorted(entries, key=lambda e: sort_key(e[0]))
    data = bytearray()
    idx = bytearray()
    for word, article in entries:
        art = article.encode('utf-8')
        idx += word.encode('utf-8') + b'\0' + struct.pack('>II', len(data), len(art))
        data += art
    with open(base + '.idx', 'wb') as f:
        f.write(idx)
    syn_count = 0
    if synonyms:
        words = [e[0] for e in entries]
        syn = bytearray()
        for s, target in sorted(synonyms, key=lambda e: sort_key(e[0])):
            syn += s.encode('utf-8') + b'\0' + struct.pack('>I', words.index(target))
            syn_count += 1
        with open(base + '.syn', 'wb') as f:
            f.write(syn)
    if dictzip:
        comp = zlib.compressobj(9, zlib.DEFLATED, -15)
        sizes, body = [], bytearray()
        for i in range(0, len(data), chunk):
            part = comp.compress(bytes(data[i:i + chunk]))
            last = i + chunk >= len(data)
            part += comp.flush(zlib.Z_FINISH if last else zlib.Z_FULL_FLUSH)
            sizes.append(len(part))
            body += part
        ra = struct.pack('<HHH', 1, chunk, len(sizes)) + b''.join(struct.pack('<H', s) for s in sizes)
        extra = b'RA' + struct.pack('<H', len(ra)) + ra
        header = b'\x1f\x8b\x08\x04' + b'\0\0\0\0' + b'\x02\x03' + struct.pack('<H', len(extra)) + extra
        trailer = struct.pack('<II', zlib.crc32(bytes(data)) & 0xffffffff, len(data) & 0xffffffff)
        with open(base + '.dict.dz', 'wb') as f:
            f.write(header + body + trailer)
    else:
        with open(base + '.dict', 'wb') as f:
            f.write(data)
    ifo = ["StarDict's dict ifo file", 'version=2.4.2', 'bookname=' + bookname, 'wordcount=%d' % len(entries),
           'idxfilesize=%d' % len(idx), 'sametypesequence=' + typeseq]
    if syn_count:
        ifo.append('synwordcount=%d' % syn_count)
    with open(base + '.ifo', 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(ifo) + '\n')


write_dict('dict_a', 'Test A', [
    ('Apple', 'A round fruit of a tree of the rose family.'),
    ('book', 'A written or printed work of pages bound together.'),
    ('bookcase', 'A set of shelves for books.'),
    ('дом', 'house, home'),
    ('привет', 'hello'),
], 'm', dictzip=True, synonyms=[('books', 'book'), ('дома', 'дом')])

write_dict('dict_b', 'Test B', [
    ('book', '<b>book</b><br/>to reserve a seat &amp; a room'),
], 'h')
