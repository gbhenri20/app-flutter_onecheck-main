class LogOperacao {
  const LogOperacao({
    required this.id,
    required this.acao,
    this.usuarioId,
    this.entidade,
    this.entidadeId,
    this.detalhes,
    this.ip,
    this.createdAt,
  });

  final String id;
  final String acao;
  final String? usuarioId;
  final String? entidade;
  final String? entidadeId;
  final String? detalhes;
  final String? ip;
  final DateTime? createdAt;

  factory LogOperacao.fromJson(Map<String, dynamic> json) {
    return LogOperacao(
      id: json['id']?.toString() ?? '',
      acao: json['acao'] as String? ?? '',
      usuarioId: json['usuario_id'] as String?,
      entidade: json['entidade'] as String?,
      entidadeId: json['entidade_id'] as String?,
      detalhes: json['detalhes'] as String?,
      ip: json['ip'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}
