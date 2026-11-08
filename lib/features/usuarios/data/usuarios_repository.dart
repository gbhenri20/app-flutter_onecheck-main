import '../../../core/network/dio_client.dart';
import '../../../core/network/paged.dart';
import '../../auth/domain/user.dart';
import '../domain/mfa_admin.dart';

class UsuariosRepository {
  UsuariosRepository(this._client);
  final DioClient _client;

  Future<PageResult<User>> listar({
    int pagina = 1,
    int porPagina = 20,
    String? role,
  }) async {
    final res = await _client.get<List<User>>(
      '/usuarios',
      query: {
        'pagina': pagina,
        'por_pagina': porPagina,
        if (role != null && role.isNotEmpty) 'role': role,
      },
      parser: (raw) => parseList(raw, User.fromJson),
    );
    return pageFrom(res);
  }

  Future<User> obter(String id) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/usuarios/$id',
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return User.fromJson(res.dados ?? {});
  }

  Future<User> criar({
    required String nome,
    required String email,
    required String senha,
    required String role,
    String? cpf,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/usuarios',
      data: {
        'nome': nome,
        'email': email,
        'senha': senha,
        'role': role,
        if (cpf != null && cpf.isNotEmpty) 'cpf': cpf,
      },
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return User.fromJson(res.dados ?? {});
  }

  Future<User> atualizar(
    String id, {
    String? nome,
    String? email,
    String? role,
    String? senha,
    bool? mfaEnabled,
  }) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/usuarios/$id',
      data: {
        if (nome != null) 'nome': nome,
        if (email != null) 'email': email,
        if (role != null) 'role': role,
        if (senha != null && senha.isNotEmpty) 'senha': senha,
        if (mfaEnabled != null) 'mfa_enabled': mfaEnabled,
      },
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return User.fromJson(res.dados ?? {});
  }

  Future<void> excluir(String id) async {
    await _client.delete('/usuarios/$id');
  }

  Future<MfaAdminSetup> setupMfa(String usuarioId) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/usuarios/$usuarioId/mfa/setup',
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return MfaAdminSetup.fromJson(res.dados ?? {});
  }

  Future<User> habilitarMfa(
    String usuarioId, {
    String? secret,
    String? codigo,
  }) async {
    final data = (secret != null && codigo != null)
        ? {'secret': secret, 'codigo': codigo}
        : null;
    final res = await _client.post<Map<String, dynamic>>(
      '/usuarios/$usuarioId/mfa/habilitar',
      data: data,
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return User.fromJson(res.dados ?? {});
  }

  Future<User> desabilitarMfa(String usuarioId) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/usuarios/$usuarioId/mfa/desabilitar',
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return User.fromJson(res.dados ?? {});
  }
}
