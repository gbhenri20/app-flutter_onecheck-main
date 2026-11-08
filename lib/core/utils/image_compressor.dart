import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageCompressor {
  const ImageCompressor({
    this.maxWidth = 1600,
    this.quality = 75,
  });

  final int maxWidth;
  final int quality;

  /// Comprime em JPEG usando apenas Dart, para funcionar no Web (FlutLab)
  /// e no Android sem plugin nativo.
  Future<CompressedImage> compress({
    String path = '',
    Uint8List? bytes,
    String filename = 'foto.jpg',
  }) async {
    final data = bytes;
    if (data == null || data.isEmpty) {
      throw StateError(
        'A imagem precisa ser lida em memória. No navegador não há caminho de arquivo local.',
      );
    }

    final decoded = img.decodeImage(data);
    if (decoded == null) {
      return CompressedImage(
        bytes: data,
        filename: _jpegName(filename),
        mimeType: 'image/jpeg',
      );
    }

    final resized = decoded.width > maxWidth
        ? img.copyResize(decoded, width: maxWidth)
        : decoded;
    final encoded = img.encodeJpg(resized, quality: quality.clamp(40, 95));
    return CompressedImage(
      bytes: encoded,
      filename: _jpegName(filename),
      mimeType: 'image/jpeg',
    );
  }

  static String _jpegName(String filename) {
    final dot = filename.lastIndexOf('.');
    final stem = dot > 0 ? filename.substring(0, dot) : filename;
    final safe = stem.trim().isEmpty ? 'foto' : stem.trim();
    return '$safe.jpg';
  }
}

class CompressedImage {
  const CompressedImage({
    required this.bytes,
    required this.filename,
    required this.mimeType,
    this.localPath,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;
  final String? localPath;
}
