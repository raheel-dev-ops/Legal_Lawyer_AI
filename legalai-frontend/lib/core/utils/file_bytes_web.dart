import 'dart:html' as html;
import 'dart:typed_data';

Future<Uint8List> readBytesImpl(String pathOrUrl) async {
  final response = await html.HttpRequest.request(
    pathOrUrl,
    responseType: 'arraybuffer',
  );
  final buffer = response.response as ByteBuffer?;
  if (buffer == null) {
    return Uint8List(0);
  }
  return buffer.asUint8List();
}
