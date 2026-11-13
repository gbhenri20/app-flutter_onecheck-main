import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:one_check/core/location/endereco_geocoder.dart';
import 'package:one_check/core/location/viacep.dart';
import 'package:one_check/features/checklist/domain/checklist_models.dart';

void main() {
  test('normaliza CEP com máscara e rejeita texto curto', () {
    expect(normalizarCep('01001-000'), '01001000');
    expect(normalizarCep('123'), isNull);
  });

  test('ViaCEP inválido vira exceção de CEP não encontrado', () {
    expect(
      () => ViaCepEndereco.fromJson({'erro': true}),
      throwsA(
        isA<ViaCepException>().having((e) => e.naoEncontrado, 'naoEncontrado', isTrue),
      ),
    );
  });

  test('endereço confere com o ViaCEP mesmo sem acento', () {
    const via = ViaCepEndereco(
      cep: '01001-000',
      logradouro: 'Praça da Sé',
      bairro: 'Sé',
      cidade: 'São Paulo',
      uf: 'SP',
    );
    const igual = Endereco(
      rua: 'Praca da Se',
      bairro: 'Sé',
      cidade: 'Sao Paulo',
      estado: 'sp',
      cep: '01001000',
    );
    const divergente = Endereco(
      rua: 'Avenida Paulista',
      cidade: 'São Paulo',
      estado: 'SP',
      cep: '01001000',
    );
    const soCidade = Endereco(
      cidade: 'São Paulo',
      estado: 'SP',
      cep: '01001000',
    );

    expect(conferirEndereco(igual, via), CepConferencia.confere);
    expect(conferirEndereco(divergente, via), CepConferencia.diverge);
    expect(
      conferirEndereco(
        soCidade,
        const ViaCepEndereco(
          cep: '01000-000',
          logradouro: '',
          bairro: '',
          cidade: 'São Paulo',
          uf: 'SP',
        ),
      ),
      CepConferencia.confere,
    );
  });

  test('ponto do Nominatim lê latitude e longitude', () {
    expect(
      pontoDeNominatim([
        {'lat': '-23.5505', 'lon': '-46.6333'},
      ]),
      const LatLng(-23.5505, -46.6333),
    );
    expect(pontoDeNominatim(const []), isNull);
  });

  test('endereço sem rua, cidade, CEP ou coordenadas não tem localização', () {
    expect(const Endereco().temLocalizacao, isFalse);
    expect(const Endereco(cep: '01001000').temLocalizacao, isTrue);
  });
}
