class ApiResponse<T> {
  const ApiResponse({
    required this.sucesso,
    this.dados,
    this.erro,
    this.erros,
    this.paginacao,
  });

  final bool sucesso;
  final T? dados;
  final String? erro;
  final Object? erros;
  final Map<String, dynamic>? paginacao;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(Object? raw)? mapData,
  }) {
    final raw = json['dados'];
    return ApiResponse<T>(
      sucesso: json['sucesso'] as bool? ?? false,
      dados: raw == null
          ? null
          : (mapData != null ? mapData(raw) : raw as T?),
      erro: json['erro'] as String?,
      erros: json['erros'],
      paginacao: json['paginacao'] is Map
          ? Map<String, dynamic>.from(json['paginacao'] as Map)
          : null,
    );
  }
}
