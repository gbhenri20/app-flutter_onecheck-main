import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/local_database.dart';
import '../../../core/utils/image_compressor.dart';
import '../domain/checklist_models.dart';

class ChecklistRepository {
  ChecklistRepository({
    required DioClient client,
    required LocalDatabase localDb,
    required ImageCompressor compressor,
  })  : _client = client,
        _localDb = localDb,
        _compressor = compressor;

  final DioClient _client;
  final LocalDatabase _localDb;
  final ImageCompressor _compressor;

  Future<Checklist> getChecklist(String id) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/checklists/$id',
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    final ck = Checklist.fromJson(res.dados ?? {});
    await _localDb.saveDraft('checklist_$id', res.dados ?? {});
    return ck;
  }

  Future<List<ItemVistoriaCatalogo>> listItensCatalogo() async {
    final res = await _client.get<List<ItemVistoriaCatalogo>>(
      '/itens-vistoria',
      parser: (raw) {
        final list = raw as List? ?? const [];
        return list
            .whereType<Map>()
            .map(
              (e) => ItemVistoriaCatalogo.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      },
    );
    return res.dados ?? const [];
  }

  Future<ChecklistItem> upsertItem({
    required String checklistId,
    required String comodoId,
    required String itemVistoriaId,
    required String estado,
    String? observacao,
    String? existingItemId,
  }) async {
    if (existingItemId != null) {
      final res = await _client.put<Map<String, dynamic>>(
        '/checklists/$checklistId/itens/$existingItemId',
        data: {
          'estado': estado,
          if (observacao != null) 'observacao': observacao,
        },
        parser: (raw) => Map<String, dynamic>.from(raw as Map),
      );
      await _localDb.appendOpLog({
        'tipo': 'checklist_item_update',
        'resultado': 'ok',
        'detalhe': existingItemId,
      });
      return ChecklistItem.fromJson(res.dados ?? {});
    }

    final res = await _client.post<Map<String, dynamic>>(
      '/checklists/$checklistId/itens',
      data: {
        'comodo_id': comodoId,
        'item_vistoria_id': itemVistoriaId,
        'estado': estado,
        if (observacao != null) 'observacao': observacao,
      },
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    await _localDb.appendOpLog({
      'tipo': 'checklist_item_create',
      'resultado': 'ok',
      'detalhe': itemVistoriaId,
    });
    return ChecklistItem.fromJson(res.dados ?? {});
  }

  Future<FotoItem> uploadFoto({
    required String checklistId,
    required String itemId,
    required String filePath,
    Uint8List? bytes,
    String filename = 'foto.jpg',
  }) async {
    try {
      final compressed = bytes == null
          ? null
          : await _compressor.compress(bytes: bytes, filename: filename);
      final uploadBytes = compressed?.bytes ?? bytes;
      final uploadName = compressed?.filename ?? filename;
      if (uploadBytes == null) {
        throw StateError(
          'Não foi possível ler a imagem. Selecione o arquivo novamente.',
        );
      }

      final form = FormData.fromMap({
        'foto': MultipartFile.fromBytes(
          uploadBytes,
          filename: uploadName,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      final res = await _client.upload<Map<String, dynamic>>(
        '/checklists/$checklistId/itens/$itemId/fotos',
        formData: form,
        parser: (raw) => Map<String, dynamic>.from(raw as Map),
      );
      await _localDb.appendOpLog({
        'tipo': 'foto_upload',
        'resultado': 'ok',
        'detalhe': itemId,
      });
      final dados = res.dados ?? {};
      return FotoItem(
        id: dados['id'] as String,
        url: dados['url'] as String? ?? '',
      );
    } on AppException catch (e) {
      if (e.isNetwork && bytes != null) {
        await _localDb.enqueueSync({
          'id': 'foto_${checklistId}_$itemId',
          'type': 'foto_upload',
          'checklistId': checklistId,
          'itemId': itemId,
          'filename': filename,
          'bytesBase64': base64Encode(bytes),
        });
        await _localDb.appendOpLog({
          'tipo': 'foto_upload',
          'resultado': 'pendente',
          'detalhe': 'Aguardando conexão para enviar a foto',
        });
        throw const AppException(
          'Sem conexão. A foto ficou na fila e só será concluída depois que a API confirmar o envio.',
          code: 'queued',
        );
      }
      rethrow;
    }
  }

  Future<void> deleteFoto({
    required String checklistId,
    required String itemId,
    required String fotoId,
  }) async {
    await _client.delete('/checklists/$checklistId/itens/$itemId/fotos/$fotoId');
    await _localDb.appendOpLog({
      'tipo': 'foto_delete',
      'resultado': 'ok',
      'detalhe': fotoId,
    });
  }

  Future<Checklist> submeter(String checklistId) async {
    final res = await _client.patch<Map<String, dynamic>>(
      '/checklists/$checklistId/submeter',
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    await _localDb.appendOpLog({
      'tipo': 'checklist_submeter',
      'resultado': 'ok',
      'detalhe': checklistId,
    });
    await _localDb.deleteDraft('checklist_$checklistId');
    return Checklist.fromJson(res.dados ?? {});
  }

  Future<Checklist> aceitar(String checklistId) async {
    final res = await _client.patch<Map<String, dynamic>>(
      '/checklists/$checklistId/aceitar',
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Checklist.fromJson(res.dados ?? {});
  }

  Future<Checklist> rejeitar(
    String checklistId, {
    required String motivo,
  }) async {
    final res = await _client.patch<Map<String, dynamic>>(
      '/checklists/$checklistId/rejeitar',
      data: {'motivo': motivo},
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Checklist.fromJson(res.dados ?? {});
  }

  Future<Checklist> enviarParaAceite(String checklistId) async {
    final res = await _client.patch<Map<String, dynamic>>(
      '/checklists/$checklistId/enviar-para-aceite',
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    await _localDb.appendOpLog({
      'tipo': 'checklist_enviar_aceite',
      'resultado': 'ok',
      'detalhe': checklistId,
    });
    return Checklist.fromJson(res.dados ?? {});
  }

  Future<Checklist> criar({
    required String contratoId,
    required String tipo,
    required String vistoriadorId,
    String? dataVistoria,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/contratos/$contratoId/checklists',
      data: {
        'tipo': tipo,
        'vistoriador_id': vistoriadorId,
        if (dataVistoria != null) 'data_vistoria': dataVistoria,
      },
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Checklist.fromJson(res.dados ?? {});
  }

  Future<Uint8List> baixarPdf(String checklistId) {
    return _client.getBytes('/checklists/$checklistId/pdf');
  }
}
