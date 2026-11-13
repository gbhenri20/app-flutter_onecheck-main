import 'package:dio/dio.dart';

import '../../features/checklist/domain/checklist_models.dart';

/// Resultado de uma consulta ao ViaCEP.
class ViaCepEndereco {
  const ViaCepEndereco({
    required this.cep,
    required this.logradouro,
    required this.bairro,
    required this.cidade,
    required this.uf,
  });

  final String cep;
  final String logradouro;
  final String bairro;
  final String cidade;
  final String uf;

  factory ViaCepEndereco.fromJson(Map<String, dynamic> json) {
    if (json['erro'] == true) {
      throw const ViaCepException(
        'CEP não encontrado no ViaCEP',
        naoEncontrado: true,
      );
    }
    return ViaCepEndereco(
      cep: json['cep'] as String? ?? '',
      logradouro: json['logradouro'] as String? ?? '',
      bairro: json['bairro'] as String? ?? '',
      cidade: json['localidade'] as String? ?? '',
      uf: json['uf'] as String? ?? '',
    );
  }
}

class ViaCepException implements Exception {
  const ViaCepException(this.mensagem, {this.naoEncontrado = false});

  final String mensagem;
  final bool naoEncontrado;

  @override
  String toString() => mensagem;
}

enum CepConferencia { confere, diverge, invalido, semCep, indisponivel }

/// Oito dígitos, ou null quando o texto não é um CEP.
String? normalizarCep(String valor) {
  final digitos = valor.replaceAll(RegExp(r'\D'), '');
  if (digitos.length != 8) return null;
  return digitos;
}

String _semAcento(String valor) {
  const origem = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const destino = 'aaaaaeeeeiiiiooooouuuucn';
  var texto = valor.trim().toLowerCase();
  for (var i = 0; i < origem.length; i++) {
    texto = texto.replaceAll(origem[i], destino[i]);
  }
  return texto.replaceAll(RegExp(r'\s+'), ' ');
}

bool _equivale(String? atual, String referencia) {
  final esperado = _semAcento(referencia);
  if (esperado.isEmpty) return true;
  final informado = _semAcento(atual ?? '');
  if (informado.isEmpty) return false;
  return informado == esperado || informado.startsWith(esperado);
}

/// Compara o endereço salvo com o que o ViaCEP devolveu para o mesmo CEP.
CepConferencia conferirEndereco(Endereco endereco, ViaCepEndereco via) {
  final cidadeOk = _equivale(endereco.cidade, via.cidade);
  final ufOk = _equivale(endereco.estado, via.uf);
  final ruaOk = _equivale(endereco.rua, via.logradouro);
  if (cidadeOk && ufOk && ruaOk) return CepConferencia.confere;
  return CepConferencia.diverge;
}

class ViaCepClient {
  ViaCepClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                headers: const {'Accept': 'application/json'},
              ),
            );

  final Dio _dio;
  final Map<String, ViaCepEndereco> _cache = {};

  Future<ViaCepEndereco> consultar(String cep) async {
    final digitos = normalizarCep(cep);
    if (digitos == null) {
      throw const ViaCepException('Informe um CEP com 8 dígitos');
    }
    final salvo = _cache[digitos];
    if (salvo != null) return salvo;

    try {
      final resposta = await _dio.get<dynamic>(
        'https://viacep.com.br/ws/$digitos/json/',
      );
      final corpo = resposta.data;
      if (corpo is! Map) {
        throw const ViaCepException('Resposta inválida do ViaCEP');
      }
      final endereco = ViaCepEndereco.fromJson(
        Map<String, dynamic>.from(corpo),
      );
      _cache[digitos] = endereco;
      return endereco;
    } on ViaCepException {
      rethrow;
    } on DioException {
      throw const ViaCepException('Não foi possível consultar o ViaCEP');
    }
  }

  void dispose() {
    _dio.close();
  }
}
