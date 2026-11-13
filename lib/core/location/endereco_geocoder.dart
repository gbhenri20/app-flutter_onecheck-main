import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../../features/checklist/domain/checklist_models.dart';
import 'viacep.dart';

/// Lê o primeiro ponto devolvido pelo Nominatim.
LatLng? pontoDeNominatim(Object? data) {
  if (data is! List || data.isEmpty) return null;
  final primeiro = data.first;
  if (primeiro is! Map) return null;
  final latitude = double.tryParse('${primeiro['lat']}');
  final longitude = double.tryParse('${primeiro['lon']}');
  if (latitude == null || longitude == null) return null;
  return LatLng(latitude, longitude);
}

/// Chave estável para cache de mapa e de conferência de CEP.
class LocalizacaoChave {
  LocalizacaoChave(this.endereco);

  final Endereco endereco;

  String get id => [
        endereco.latitude,
        endereco.longitude,
        endereco.cep,
        endereco.rua,
        endereco.numero,
        endereco.bairro,
        endereco.cidade,
        endereco.estado,
      ].join('|');

  @override
  bool operator ==(Object other) =>
      other is LocalizacaoChave && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class EnderecoGeocoder {
  EnderecoGeocoder({
    Dio? dio,
    this.pausa = const Duration(milliseconds: 1100),
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                headers: const {
                  'Accept': 'application/json',
                  'User-Agent': 'OneCheck/1.0 (vistoria imobiliaria)',
                },
              ),
            );

  final Dio _dio;
  final Duration pausa;
  final Map<String, LatLng?> _cache = {};
  Future<void> _fila = Future<void>.value();

  Future<LatLng?> coordenadas(Endereco endereco) {
    if (endereco.latitude != null && endereco.longitude != null) {
      return Future.value(LatLng(endereco.latitude!, endereco.longitude!));
    }
    final chave = _chave(endereco);
    if (chave == null) return Future.value(null);
    final salvo = _cache[chave];
    if (_cache.containsKey(chave)) return Future.value(salvo);

    final pendente = _fila.then((_) => _resolver(chave, endereco));
    _fila = pendente.then((_) {}, onError: (erro, detalhe) {});
    return pendente;
  }

  Future<LatLng?> _resolver(String chave, Endereco endereco) async {
    if (_cache.containsKey(chave)) return _cache[chave];
    try {
      final ponto = await _buscar(endereco);
      _cache[chave] = ponto;
      return ponto;
    } finally {
      await Future<void>.delayed(pausa);
    }
  }

  Future<LatLng?> _buscar(Endereco endereco) async {
    final estruturado = await _consultar(_parametros(endereco));
    if (estruturado != null) return estruturado;
    final texto = [
      endereco.linhaCompleta,
      if (endereco.cep != null && endereco.cep!.trim().isNotEmpty) endereco.cep,
      'Brasil',
    ].join(', ');
    if (texto.trim().isEmpty) return null;
    return _consultar({
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'br',
      'q': texto,
    });
  }

  Map<String, String> _parametros(Endereco endereco) {
    final params = <String, String>{
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'br',
    };
    final rua = endereco.rua?.trim() ?? '';
    final numero = endereco.numero?.trim() ?? '';
    if (rua.isNotEmpty) {
      params['street'] = numero.isEmpty ? rua : '$rua, $numero';
    }
    final cidade = endereco.cidade?.trim() ?? '';
    final estado = endereco.estado?.trim() ?? '';
    final cep = normalizarCep(endereco.cep ?? '');
    if (cidade.isNotEmpty) params['city'] = cidade;
    if (estado.isNotEmpty) params['state'] = estado;
    if (cep != null) params['postalcode'] = cep;
    return params;
  }

  Future<LatLng?> _consultar(Map<String, String> params) async {
    final resposta = await _dio.get<dynamic>(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: params,
    );
    return pontoDeNominatim(resposta.data);
  }

  String? _chave(Endereco endereco) {
    final cep = normalizarCep(endereco.cep ?? '');
    final partes = [
      endereco.rua?.trim() ?? '',
      endereco.numero?.trim() ?? '',
      endereco.bairro?.trim() ?? '',
      endereco.cidade?.trim() ?? '',
      endereco.estado?.trim() ?? '',
      cep ?? '',
    ].where((parte) => parte.isNotEmpty).join('|');
    if (partes.isEmpty) return null;
    return partes;
  }

  void dispose() {
    _dio.close();
  }
}
