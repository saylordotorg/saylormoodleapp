"""Rewrite 8-bit RGBA PNGs as RGB (no alpha channel). Standard library only."""
import struct
import sys
import zlib


def read_chunks(data):
    pos = 8
    while pos < len(data):
        length, kind = struct.unpack('>I4s', data[pos:pos + 8])
        yield kind, data[pos + 8:pos + 8 + length]
        pos += 12 + length


def chunk(kind, payload):
    return struct.pack('>I', len(payload)) + kind + payload + struct.pack('>I', zlib.crc32(kind + payload) & 0xffffffff)


def strip(path):
    data = open(path, 'rb').read()
    chunks = list(read_chunks(data))
    width, height, depth, ctype, _, _, interlace = struct.unpack('>IIBBBBB', chunks[0][1])
    if ctype == 2:
        return
    if (depth, ctype, interlace) != (8, 6, 0):
        raise SystemExit(f'{path}: unsupported PNG format')

    raw = zlib.decompress(b''.join(body for kind, body in chunks if kind == b'IDAT'))
    stride = width * 4
    prev = bytearray(stride)
    out = bytearray()
    pos = 0
    for _ in range(height):
        ftype = raw[pos]
        row = bytearray(raw[pos + 1:pos + 1 + stride])
        pos += 1 + stride
        if ftype == 1:
            for i in range(4, stride):
                row[i] = (row[i] + row[i - 4]) & 255
        elif ftype == 2:
            for i in range(stride):
                row[i] = (row[i] + prev[i]) & 255
        elif ftype == 3:
            for i in range(stride):
                left = row[i - 4] if i >= 4 else 0
                row[i] = (row[i] + ((left + prev[i]) >> 1)) & 255
        elif ftype == 4:
            for i in range(stride):
                a = row[i - 4] if i >= 4 else 0
                b = prev[i]
                c = prev[i - 4] if i >= 4 else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pred = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                row[i] = (row[i] + pred) & 255
        prev = row
        rgb = bytearray(width * 3)
        rgb[0::3] = row[0::4]
        rgb[1::3] = row[1::4]
        rgb[2::3] = row[2::4]
        out += b'\x00' + rgb

    ihdr = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr) + chunk(b'IDAT', zlib.compress(bytes(out), 9)) + chunk(b'IEND', b'')
    open(path, 'wb').write(png)


for target in sys.argv[1:]:
    strip(target)
