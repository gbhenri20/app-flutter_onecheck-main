import '../../../core/network/dio_client.dart';
import '../../../core/network/paged.dart';
import '../../checklist/domain/checklist_models.dart';

class ContratosRepository {
  ContratosRepository(this._client);
  final DioClient _client;

  Future<PageResult<Contrato>> listar({
    int pagina = 1,
    int porPagina = 50,
    String? status,
    String? imovelId,
  }) async {
    final res = await _client.get<List<Contrato>>(
      '/contratos',
      query: {
        'pagina': pagina,
        'por_pagina': porPagina,
        if (status != null && status.isNotEmpty) 'status': status,
        if (imovelId != null && imovelId.isNotEmpty) 'imovel_id': imovelId,
      },
      parser: (raw) => parseList(raw, Contrato.fromJson),
    );
    return pageFrom(res);
  }

  Future<Contrato> obter(String id) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/contratos/$id',
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Contrato.fromJson(res.dados ?? {});
  }

  Future<Contrato> criar({
    required String imovelId,
    required String locatarioId,
    required String dataInicio,
    required String dataFim,
    double? valorMensal,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/contratos',
      data: {
        'imovel_id': imovelId,
        'locatario_id': locatarioId,
        'data_inicio': dataInicio,
        'data_fim': dataFim,
        if (valorMensal != null) 'valor_mensal': valorMensal,
      },
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Contrato.fromJson(res.dados ?? {});
  }

  Future<Contrato> encerrar(String id) async {
    final res = await _client.patch<Map<String, dynamic>>(
      '/contratos/$id/encerrar',
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Contrato.fromJson(res.dados ?? {});
  }

  Future<Contrato> cancelar(String id) async {
    final res = await _client.patch<Map<String, dynamic>>(
      '/contratos/$id/cancelar',
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Contrato.fromJson(res.dados ?? {});
  }

  Future<List<Agendamento>> agendamentos(String contratoId) async {
    final res = await _client.get<List<Agendamento>>(
      '/contratos/$contratoId/agendamentos',
      parser: (raw) => parseList(raw, Agendamento.fromJson),
    );
    return res.dados ?? const [];
  }

  Future<Agendamento> criarAgendamento({
    required String contratoId,
    required String tipo,
    required String dataAgendada,
    String? observacao,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/contratos/$contratoId/agendamentos',
      data: {
        'tipo': tipo,
        'data_agendada': dataAgendada,
        if (observacao != null && observacao.isNotEmpty) 'observacao': observacao,
      },
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Agendamento.fromJson(res.dados ?? {});
  }

  Future<Agendamento> atualizarAgendamento({
    required String agendamentoId,
    String? tipo,
    String? dataAgendada,
    String? observacao,
  }) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/agendamentos/$agendamentoId',
      data: {
        if (tipo != null) 'tipo': tipo,
        if (dataAgendada != null) 'data_agendada': dataAgendada,
        if (observacao != null) 'observacao': observacao,
      },
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return Agendamento.fromJson(res.dados ?? {});
  }

  Future<void> cancelarAgendamento(String agendamentoId) async {
    await _client.delete('/agendamentos/$agendamentoId');
  }

  Future<List<Checklist>> checklists(String contratoId) async {
    final res = await _client.get<List<Checklist>>(
      '/contratos/$contratoId/checklists',
      parser: (raw) => parseList(raw, Checklist.fromJson),
    );
    return res.dados ?? const [];
  }
}
