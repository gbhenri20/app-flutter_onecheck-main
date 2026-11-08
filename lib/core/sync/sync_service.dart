import 'dart:convert';
import 'dart:typed_data';

import '../../features/checklist/data/checklist_repository.dart';
import '../errors/app_exception.dart';
import '../storage/local_database.dart';

/// Reenvia fotos que falharam por falta de conexão.
/// Só remove o item da fila depois da confirmação da API.
class SyncService {
  SyncService({
    required LocalDatabase localDb,
    required ChecklistRepository checklistRepository,
  })  : _db = localDb,
        _checklist = checklistRepository;

  final LocalDatabase _db;
  final ChecklistRepository _checklist;

  Future<SyncFlushResult> flush() async {
    final pending = _db.pendingSync();
    var synced = 0;
    var failed = 0;
    for (final op in pending) {
      if (op['type'] != 'foto_upload') {
        failed++;
        continue;
      }
      final b64 = op['bytesBase64'] as String?;
      final checklistId = op['checklistId'] as String?;
      final itemId = op['itemId'] as String?;
      final id = op['id'] as String?;
      if (b64 == null || checklistId == null || itemId == null || id == null) {
        failed++;
        continue;
      }
      try {
        await _checklist.uploadFoto(
          checklistId: checklistId,
          itemId: itemId,
          filePath: '',
          bytes: Uint8List.fromList(base64Decode(b64)),
          filename: op['filename'] as String? ?? 'foto.jpg',
        );
        await _db.removeSync(id);
        await _db.appendOpLog({
          'tipo': 'foto_upload',
          'resultado': 'sincronizado',
          'detalhe': itemId,
        });
        synced++;
      } on AppException catch (e) {
        if (e.code == 'queued') {
          failed++;
          continue;
        }
        if (!e.isNetwork) {
          await _db.removeSync(id);
          await _db.appendOpLog({
            'tipo': 'foto_upload',
            'resultado': 'erro',
            'detalhe': e.message,
          });
        }
        failed++;
      } catch (_) {
        failed++;
      }
    }
    return SyncFlushResult(synced: synced, failed: failed);
  }
}

class SyncFlushResult {
  const SyncFlushResult({required this.synced, required this.failed});
  final int synced;
  final int failed;
}
