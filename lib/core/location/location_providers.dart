import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'endereco_geocoder.dart';
import 'viacep.dart';

final viaCepClientProvider = Provider<ViaCepClient>((ref) {
  final client = ViaCepClient();
  ref.onDispose(client.dispose);
  return client;
});

final enderecoGeocoderProvider = Provider<EnderecoGeocoder>((ref) {
  final geocoder = EnderecoGeocoder();
  ref.onDispose(geocoder.dispose);
  return geocoder;
});

final coordenadasProvider =
    FutureProvider.autoDispose.family<LatLng?, LocalizacaoChave>((ref, chave) {
  return ref.watch(enderecoGeocoderProvider).coordenadas(chave.endereco);
});

final cepConferenciaProvider = FutureProvider.autoDispose
    .family<CepConferencia, LocalizacaoChave>((ref, chave) async {
  final cep = normalizarCep(chave.endereco.cep ?? '');
  if (cep == null) return CepConferencia.semCep;
  try {
    final via = await ref.watch(viaCepClientProvider).consultar(cep);
    return conferirEndereco(chave.endereco, via);
  } on ViaCepException catch (e) {
    return e.naoEncontrado ? CepConferencia.invalido : CepConferencia.indisponivel;
  }
});
