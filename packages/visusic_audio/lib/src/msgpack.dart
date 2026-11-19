// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:convert';
import 'dart:typed_data';

/// A readable error raised while encoding or decoding MessagePack data.
final class MsgPackException implements Exception {
  /// Creates a codec error.
  const MsgPackException(this.message);

  /// Human-readable problem description.
  final String message;

  @override
  String toString() => 'MsgPackException: $message';
}

/// Minimal MessagePack encoder for the `.vsan` analysis cache.
abstract final class MsgPackEncoder {
  /// Encodes the supported subset of Dart values to MessagePack bytes.
  static Uint8List encode(Object? value) {
    final writer = BytesBuilder();
    _write(writer, value);
    return writer.toBytes();
  }

  static void _write(BytesBuilder out, Object? value) {
    if (value == null) {
      out.addByte(0xc0);
    } else if (value is bool) {
      out.addByte(value ? 0xc3 : 0xc2);
    } else if (value is int) {
      _writeInt(out, value);
    } else if (value is double) {
      out.addByte(0xcb);
      final data = ByteData(8)..setFloat64(0, value, Endian.big);
      out.add(Uint8List.view(data.buffer));
    } else if (value is String) {
      final bytes = _utf8(value);
      _writeHeader(out, bytes.length, _strFixPrefix, 0xd9, 0xda, 0xdb);
      out.add(bytes);
    } else if (value is Uint8List) {
      _writeBin(out, value);
    } else if (value is List) {
      _writeArray(out, value);
    } else if (value is Map) {
      _writeMap(out, value);
    } else {
      throw MsgPackException('Unsupported value type: ${value.runtimeType}');
    }
  }

  static void _writeInt(BytesBuilder out, int value) {
    if (value >= 0) {
      if (value <= 0x7f) {
        out.addByte(value);
      } else if (value <= 0xff) {
        out.addByte(0xcc);
        out.addByte(value);
      } else if (value <= 0xffff) {
        out.addByte(0xcd);
        _addUint16(out, value);
      } else if (value <= 0xffffffff) {
        out.addByte(0xce);
        _addUint32(out, value);
      } else {
        out.addByte(0xcf);
        _addUint64(out, value);
      }
    } else if (value >= -32) {
      out.addByte(value & 0xff);
    } else if (value >= -128) {
      out.addByte(0xd0);
      out.addByte(value & 0xff);
    } else if (value >= -0x8000) {
      out.addByte(0xd1);
      _addUint16(out, value & 0xffff);
    } else if (value >= -0x80000000) {
      out.addByte(0xd2);
      _addUint32(out, value & 0xffffffff);
    } else {
      out.addByte(0xd3);
      _addUint64(out, value & 0xffffffffffffffff);
    }
  }

  static void _writeHeader(
    BytesBuilder out,
    int length,
    List<int> fixPrefix,
    int max8,
    int max16,
    int max32,
  ) {
    final header = length < 0
        ? throw MsgPackException('Negative length is not valid.')
        : length <= fixPrefix[0]
        ? fixPrefix[1] + length
        : length <= 0xff
        ? max8
        : length <= 0xffff
        ? max16
        : max32;
    out.addByte(header);
    if (length > fixPrefix[0]) {
      if (length <= 0xff) {
        out.addByte(length);
      } else if (length <= 0xffff) {
        _addUint16(out, length);
      } else {
        _addUint32(out, length);
      }
    }
  }

  static const List<int> _strFixPrefix = <int>[31, 0xa0];

  static void _writeBin(BytesBuilder out, Uint8List bytes) {
    if (bytes.length <= 0xff) {
      out.addByte(0xc4);
      out.addByte(bytes.length);
    } else if (bytes.length <= 0xffff) {
      out.addByte(0xc5);
      _addUint16(out, bytes.length);
    } else {
      out.addByte(0xc6);
      _addUint32(out, bytes.length);
    }
    out.add(bytes);
  }

  static void _writeArray(BytesBuilder out, List<Object?> values) {
    if (values.length <= 0x0f) {
      out.addByte(0x90 + values.length);
    } else if (values.length <= 0xffff) {
      out.addByte(0xdc);
      _addUint16(out, values.length);
    } else {
      out.addByte(0xdd);
      _addUint32(out, values.length);
    }
    for (final value in values) {
      _write(out, value);
    }
  }

  static void _writeMap(BytesBuilder out, Map<Object?, Object?> values) {
    if (values.length <= 0x0f) {
      out.addByte(0x80 + values.length);
    } else if (values.length <= 0xffff) {
      out.addByte(0xde);
      _addUint16(out, values.length);
    } else {
      out.addByte(0xdf);
      _addUint32(out, values.length);
    }
    for (final entry in values.entries) {
      _write(out, entry.key);
      _write(out, entry.value);
    }
  }

  static void _addUint16(BytesBuilder out, int value) {
    final data = ByteData(2)..setUint16(0, value, Endian.big);
    out.add(Uint8List.view(data.buffer));
  }

  static void _addUint32(BytesBuilder out, int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.big);
    out.add(Uint8List.view(data.buffer));
  }

  static void _addUint64(BytesBuilder out, int value) {
    final data = ByteData(8)..setUint64(0, value, Endian.big);
    out.add(Uint8List.view(data.buffer));
  }

  static Uint8List _utf8(String value) {
    return Uint8List.fromList(utf8.encode(value));
  }
}

/// Minimal MessagePack decoder matching [MsgPackEncoder].
abstract final class MsgPackDecoder {
  /// Decodes MessagePack bytes into the supported Dart value subset.
  static Object? decode(Uint8List bytes) {
    final reader = _Reader(bytes);
    final value = _read(reader);
    if (!reader.isDone) {
      throw const MsgPackException('Trailing bytes after the message.');
    }
    return value;
  }

  static Object? _read(_Reader reader) {
    final byte = reader.readByte();
    if (byte <= 0x7f) {
      return byte;
    }
    if (byte >= 0xe0) {
      return byte - 0x100;
    }
    if (byte >= 0xa0 && byte <= 0xbf) {
      return reader.readString(byte & 0x1f);
    }
    if (byte >= 0x90 && byte <= 0x9f) {
      return reader.readList(byte & 0x0f);
    }
    if (byte >= 0x80 && byte <= 0x8f) {
      return reader.readMap(byte & 0x0f);
    }
    return switch (byte) {
      0xc0 => null,
      0xc2 => false,
      0xc3 => true,
      0xca => reader.readFloat32(),
      0xcb => reader.readFloat64(),
      0xcc => reader.readUint8(),
      0xcd => reader.readUint16(),
      0xce => reader.readUint32(),
      0xcf => reader.readUint64(),
      0xd0 => reader.readInt8(),
      0xd1 => reader.readInt16(),
      0xd2 => reader.readInt32(),
      0xd3 => reader.readInt64(),
      0xd9 => reader.readString(reader.readUint8()),
      0xda => reader.readString(reader.readUint16()),
      0xdb => reader.readString(reader.readUint32()),
      0xc4 => reader.readBin(reader.readUint8()),
      0xc5 => reader.readBin(reader.readUint16()),
      0xc6 => reader.readBin(reader.readUint32()),
      0xdc => reader.readList(reader.readUint16()),
      0xdd => reader.readList(reader.readUint32()),
      0xde => reader.readMap(reader.readUint16()),
      0xdf => reader.readMap(reader.readUint32()),
      _ => throw MsgPackException(
        'Unsupported header 0x${byte.toRadixString(16)}',
      ),
    };
  }
}

final class _Reader {
  _Reader(this.bytes);
  final Uint8List bytes;
  int _offset = 0;

  bool get isDone => _offset >= bytes.length;

  int readByte() {
    if (_offset >= bytes.length) {
      throw const MsgPackException('Unexpected end of message.');
    }
    return bytes[_offset++];
  }

  int readUint8() => readByte();

  int readUint16() {
    final data = ByteData.sublistView(bytes, _offset, _offset + 2);
    _offset += 2;
    return data.getUint16(0, Endian.big);
  }

  int readUint32() {
    final data = ByteData.sublistView(bytes, _offset, _offset + 4);
    _offset += 4;
    return data.getUint32(0, Endian.big);
  }

  int readUint64() {
    final data = ByteData.sublistView(bytes, _offset, _offset + 8);
    _offset += 8;
    return data.getUint64(0, Endian.big);
  }

  int readInt8() {
    final data = ByteData.sublistView(bytes, _offset, _offset + 1);
    _offset += 1;
    return data.getInt8(0);
  }

  int readInt16() {
    final data = ByteData.sublistView(bytes, _offset, _offset + 2);
    _offset += 2;
    return data.getInt16(0, Endian.big);
  }

  int readInt32() {
    final data = ByteData.sublistView(bytes, _offset, _offset + 4);
    _offset += 4;
    return data.getInt32(0, Endian.big);
  }

  int readInt64() {
    final data = ByteData.sublistView(bytes, _offset, _offset + 8);
    _offset += 8;
    return data.getInt64(0, Endian.big);
  }

  double readFloat32() {
    final data = ByteData.sublistView(bytes, _offset, _offset + 4);
    _offset += 4;
    return data.getFloat32(0, Endian.big);
  }

  double readFloat64() {
    final data = ByteData.sublistView(bytes, _offset, _offset + 8);
    _offset += 8;
    return data.getFloat64(0, Endian.big);
  }

  String readString(int length) {
    _ensure(length);
    final value = utf8.decode(bytes.sublist(_offset, _offset + length));
    _offset += length;
    return value;
  }

  Uint8List readBin(int length) {
    _ensure(length);
    final value = Uint8List.sublistView(bytes, _offset, _offset + length);
    _offset += length;
    return value;
  }

  List<Object?> readList(int length) {
    _ensure(length);
    return List<Object?>.generate(length, (_) => MsgPackDecoder._read(this));
  }

  Map<Object?, Object?> readMap(int length) {
    final map = <Object?, Object?>{};
    for (var index = 0; index < length; index++) {
      final key = MsgPackDecoder._read(this);
      final value = MsgPackDecoder._read(this);
      map[key] = value;
    }
    return map;
  }

  void _ensure(int length) {
    if (_offset + length > bytes.length) {
      throw const MsgPackException('Unexpected end of message.');
    }
  }
}
