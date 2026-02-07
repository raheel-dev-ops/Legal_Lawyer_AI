import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> readBytesImpl(String pathOrUrl) async {
  return File(pathOrUrl).readAsBytes();
}
