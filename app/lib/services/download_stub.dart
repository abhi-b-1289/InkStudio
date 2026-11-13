import 'dart:typed_data';

Future<void> downloadBytes(
  Uint8List bytes,
  String filename, {
  String mimeType = 'application/octet-stream',
}) async {
  throw UnsupportedError('downloadBytes is not supported on this platform');
}

