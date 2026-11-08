import '../../../core/network/dio_client.dart';
import '../../../core/network/paged.dart';
import '../../checklist/domain/checklist_models.dart';

class ImoveisRepository {
  ImoveisRepository(this._client);
  final DioClient _client;

  Future<PageResult<Imovel>> listar({
    int pagina = 1,
    int porPagina = 20,
    String? status,
    bool comEndereco = true,
  }) async {
    final res = await _client.get<List<Imovel>>(
      '/imoveis',
      query: {
        'pagina': pagina,
        'por_pagina': porPagina,
        'com_endereco': comEndereco,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      parser: (raw) => parseList(raw, Imovel.fromJson),
    );
    return pageFrom(res);
  }

  Future<Imovel> obter(String id) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/imoveis/$id',
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Imovel.fromJson(res.dados ?? {});
  }

  Future<Endereco?> endereco(String id) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/imoveis/$id/endereco',
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    final dados = res.dados;
    if (dados == null || dados.isEmpty) return null;
    return Endereco.fromJson(dados);
  }

  Future<Imovel> criar(Map<String, dynamic> body) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/imoveis',
      data: body,
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Imovel.fromJson(res.dados ?? {});
  }

  Future<Imovel> atualizar(String id, Map<String, dynamic> body) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/imoveis/$id',
      data: body,
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Imovel.fromJson(res.dados ?? {});
  }

  Future<void> excluir(String id) async {
    await _client.delete('/imoveis/$id');
  }

  Future<Endereco> salvarEndereco(String imovelId, Map<String, dynamic> body) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/imoveis/$imovelId/endereco',
      data: body,
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Endereco.fromJson(res.dados ?? {});
  }

  Future<List<Comodo>> comodos(String imovelId) async {
    final res = await _client.get<List<Comodo>>(
      '/imoveis/$imovelId/comodos',
      parser: (raw) => parseList(raw, Comodo.fromJson),
    );
    return res.dados ?? const [];
  }

  Future<Comodo> criarComodo({
    required String imovelId,
    required String tipo,
    String? descricao,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/imoveis/$imovelId/comodos',
      data: {
        'tipo': tipo,
        if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
      },
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Comodo.fromJson(res.dados ?? {});
  }

  Future<Comodo> atualizarComodo({
    required String imovelId,
    required String comodoId,
    String? tipo,
    String? descricao,
  }) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/imoveis/$imovelId/comodos/$comodoId',
      data: {
        if (tipo != null) 'tipo': tipo,
        if (descricao != null) 'descricao': descricao,
      },
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Comodo.fromJson(res.dados ?? {});
  }

  Future<void> excluirComodo({
    required String imovelId,
    required String comodoId,
  }) async {
    await _client.delete('/imoveis/$imovelId/comodos/$comodoId');
  }
}
