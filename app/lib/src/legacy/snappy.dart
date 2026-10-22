/// Snappy decompression (the raw block format, not the framed stream), for the LevelDB tables of
/// older GUIs' IndexedDB. Pure Dart; every length and offset is checked, so a bad block throws a
/// [FormatException] and never reads outside its input or loops.
library;

import 'dart:typed_data';

/// Decompresses one Snappy block. [maxLength] bounds the stated uncompressed length.
Uint8List snappyDecompress(Uint8List src, {int maxLength = 64 << 20}) {
  var i = 0;
  // the preamble: the uncompressed length as a varint
  var length = 0, shift = 0;
  while (true) {
    if (i >= src.length || shift > 28) throw const FormatException('snappy: bad length');
    final b = src[i++];
    length |= (b & 0x7f) << shift;
    if (b < 0x80) break;
    shift += 7;
  }
  if (length > maxLength) throw FormatException('snappy: $length bytes is too large');
  final out = Uint8List(length);
  var o = 0;
  while (i < src.length) {
    final tag = src[i++];
    switch (tag & 3) {
      case 0: // literal
        var len = tag >> 2;
        if (len >= 60) {
          final n = len - 59;
          if (i + n > src.length) throw const FormatException('snappy: literal length cut off');
          len = 0;
          for (var k = 0; k < n; k++) {
            len |= src[i + k] << (8 * k);
          }
          i += n;
        }
        len += 1;
        if (len > src.length - i || len > length - o) throw const FormatException('snappy: literal overruns');
        out.setRange(o, o + len, src, i);
        i += len;
        o += len;
      case 1: // copy, 1-byte offset
        if (i >= src.length) throw const FormatException('snappy: copy cut off');
        _copy(out, o, ((tag >> 5) << 8) | src[i++], 4 + ((tag >> 2) & 7), length);
        o += 4 + ((tag >> 2) & 7);
      case 2: // copy, 2-byte offset
        if (i + 2 > src.length) throw const FormatException('snappy: copy cut off');
        _copy(out, o, src[i] | (src[i + 1] << 8), (tag >> 2) + 1, length);
        i += 2;
        o += (tag >> 2) + 1;
      default: // copy, 4-byte offset
        if (i + 4 > src.length) throw const FormatException('snappy: copy cut off');
        final off = src[i] | (src[i + 1] << 8) | (src[i + 2] << 16) | (src[i + 3] << 24);
        _copy(out, o, off, (tag >> 2) + 1, length);
        i += 4;
        o += (tag >> 2) + 1;
    }
  }
  if (o != length) throw const FormatException('snappy: shorter than stated');
  return out;
}

void _copy(Uint8List out, int o, int offset, int len, int length) {
  if (offset <= 0 || offset > o || len > length - o) throw const FormatException('snappy: bad copy');
  // byte by byte: a copy may overlap what it writes (a run)
  for (var k = 0; k < len; k++) {
    out[o + k] = out[o + k - offset];
  }
}
