
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/network/dio_client.dart';
import '../domain/problema.dart';

class ProblemasRepository {
  ProblemasRepository(this._client);
  final DioClient _client;

  Future<List<Problema>> listByContrato(String contratoId) async {
    final res = await _client.get<List<Problema>>(
      '/contratos/$contratoId/problemas',
      parser: (raw) {
        final list = raw as List? ?? const [];
        return list
            .whereType<Map>()
            .map((e) => Problema.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
    return res.dados ?? const [];
  }

  Future<Problema> get(String id) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/problemas/$id',
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Problema.fromJson(res.dados ?? {});
  }

  Future<Problema> criar({
    required String contratoId,
    required String titulo,
    required String descricao,
    String? comodoId,
    String prioridade = 'normal',
    Uint8List? foto,
    String? fotoFilename,
  }) async {
    if (foto != null) {
      final form = FormData.fromMap({
        'titulo': titulo,
        'descricao': descricao,
        'prioridade': prioridade,
        if (comodoId != null) 'comodo_id': comodoId,
        'foto': MultipartFile.fromBytes(
          foto,
          filename: fotoFilename ?? 'foto.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      });
      final res = await _client.upload<Map<String, dynamic>>(
        '/contratos/$contratoId/problemas',
        formData: form,
        parser: (raw) => Map<String, dynamic>.from(raw as Map),
      );
      return Problema.fromJson(res.dados ?? {});
    }

    final res = await _client.post<Map<String, dynamic>>(
      '/contratos/$contratoId/problemas',
      data: {
        'titulo': titulo,
        'descricao': descricao,
        'prioridade': prioridade,
        if (comodoId != null) 'comodo_id': comodoId,
      },
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Problema.fromJson(res.dados ?? {});
  }

  Future<Problema> atualizarStatus({
    required String problemaId,
    required String status,
  }) async {
    final res = await _client.patch<Map<String, dynamic>>(
      '/problemas/$problemaId/status',
      data: {'status': status},
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Problema.fromJson(res.dados ?? {});
  }

  Future<AtualizacaoProblema> registrarAtualizacao({
    required String problemaId,
    required String descricao,
    Uint8List? foto,
    String? fotoFilename,
  }) async {
    if (foto != null) {
      final form = FormData.fromMap({
        'descricao': descricao,
        'foto': MultipartFile.fromBytes(
          foto,
          filename: fotoFilename ?? 'reparo.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      });
      final res = await _client.upload<Map<String, dynamic>>(
        '/problemas/$problemaId/atualizacoes',
        formData: form,
        parser: (raw) => Map<String, dynamic>.from(raw as Map),
      );
      return AtualizacaoProblema.fromJson(res.dados ?? {});
    }
    final res = await _client.post<Map<String, dynamic>>(
      '/problemas/$problemaId/atualizacoes',
      data: {'descricao': descricao},
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return AtualizacaoProblema.fromJson(res.dados ?? {});
  }
}
