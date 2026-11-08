import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/paged.dart';
import '../../auth/domain/user.dart';
import '../domain/log_operacao.dart';

class AuditoriaRepository {
  AuditoriaRepository(this._client);
  final DioClient _client;

  Future<PageResult<LogOperacao>> listar({
    required UserRole? role,
    int pagina = 1,
    int porPagina = 20,
    String? acao,
    String? entidade,
    String? usuarioId,
    String? de,
    String? ate,
  }) async {
    if (role != UserRole.admin) {
      throw const AppException(
        'O histórico de logs é exclusivo do administrador.',
        statusCode: 403,
      );
    }
    final res = await _client.get<List<LogOperacao>>(
      '/logs',
      query: {
        'pagina': pagina,
        'por_pagina': porPagina,
        if (acao != null && acao.isNotEmpty) 'acao': acao,
        if (entidade != null && entidade.isNotEmpty) 'entidade': entidade,
        if (usuarioId != null && usuarioId.isNotEmpty) 'usuario_id': usuarioId,
        if (de != null && de.isNotEmpty) 'de': de,
        if (ate != null && ate.isNotEmpty) 'ate': ate,
      },
      parser: (raw) => parseList(raw, LogOperacao.fromJson),
    );
    return pageFrom(res);
  }

  Future<Map<String, dynamic>> dashboard() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/dashboard',
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return res.dados ?? {};
  }
}
