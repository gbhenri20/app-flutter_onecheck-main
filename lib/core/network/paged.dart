import 'api_response.dart';

class PageResult<T> {
  const PageResult({
    required this.items,
    this.total = 0,
    this.pagina = 1,
    this.itensPorPagina = 20,
  });

  final List<T> items;
  final int total;
  final int pagina;
  final int itensPorPagina;

  bool get hasMore => pagina * itensPorPagina < total;
}

List<T> parseList<T>(
  Object? raw,
  T Function(Map<String, dynamic> json) fromJson,
) {
  final list = raw is List ? raw : const [];
  return [
    for (final item in list)
      if (item is Map) fromJson(Map<String, dynamic>.from(item)),
  ];
}

PageResult<T> pageFrom<T>(ApiResponse<List<T>> response) {
  final page = response.paginacao;
  final items = response.dados ?? <T>[];
  return PageResult<T>(
    items: items,
    total: (page?['total'] as num?)?.toInt() ?? items.length,
    pagina: (page?['pagina'] as num?)?.toInt() ?? 1,
    itensPorPagina: (page?['itensPorPagina'] as num?)?.toInt() ?? items.length,
  );
}
