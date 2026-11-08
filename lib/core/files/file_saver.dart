import 'dart:typed_data';

import 'file_saver_io.dart' if (dart.library.html) 'file_saver_web.dart' as impl;

/// Salva bytes no dispositivo ou dispara o download no navegador.
Future<void> saveBytes({
  required Uint8List bytes,
  required String filename,
  String mimeType = 'application/octet-stream',
}) {
  return impl.saveBytesImpl(
    bytes: bytes,
    filename: filename,
    mimeType: mimeType,
  );
}
