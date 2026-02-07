import 'dart:typed_data';

import 'file_bytes_stub.dart'
    if (dart.library.html) 'file_bytes_web.dart'
    if (dart.library.io) 'file_bytes_io.dart';

Future<Uint8List> readBytes(String pathOrUrl) {
  return readBytesImpl(pathOrUrl);
}
