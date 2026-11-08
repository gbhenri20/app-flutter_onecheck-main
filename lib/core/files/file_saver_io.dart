import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> saveBytesImpl({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) async {
  final dir = await getDownloadsDirectory() ?? await getTemporaryDirectory();
  final file = File(p.join(dir.path, filename));
  await file.writeAsBytes(bytes, flush: true);
}
