import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:one_check/core/network/api_response.dart';
import 'package:one_check/core/network/paged.dart';
import 'package:one_check/core/utils/image_compressor.dart';
import 'package:one_check/features/auth/domain/user.dart';
import 'package:one_check/features/checklist/domain/checklist_models.dart';

void main() {
  test('comprimir JPEG reduz a largura e não usa arquivo local', () async {
    final source = img.Image(width: 40, height: 20);
    final bytes = Uint8List.fromList(img.encodeJpg(source));
    final out = await const ImageCompressor(maxWidth: 10, quality: 60).compress(
      bytes: bytes,
      filename: 'vistoria.png',
    );
    expect(out.mimeType, 'image/jpeg');
    expect(out.filename.endsWith('.jpg'), isTrue);
    final decoded = img.decodeJpg(out.bytes);
    expect(decoded, isNotNull);
    expect(decoded!.width <= 10, isTrue);
  });

  test('imóvel e endereço leem latitude retornada pela API', () {
    final imovel = Imovel.fromJson({
      'id': 'im1',
      'tipo': 'apartamento',
      'status': 'disponivel',
      'garagem': true,
      'garagem_vagas': 1,
      'endereco': {
        'rua': 'Rua A',
        'cidade': 'São Paulo',
        'estado': 'SP',
        'latitude': -23.5,
        'longitude': -46.6,
      },
    });
    expect(imovel.garagemVagas, 1);
    expect(imovel.endereco?.latitude, -23.5);
  });

  test('usuário lê flags de MFA da API', () {
    final user = User.fromJson({
      'id': 'u1',
      'nome': 'Ana',
      'email': 'ana@onecheck.local',
      'role': 'gestor',
      'mfa_enabled': true,
      'mfa_configurado': true,
      'mfa_ativo': true,
    });
    expect(user.isGestor, isTrue);
    expect(user.mfaAtivo, isTrue);
  });

  test('paginação usa itensPorPagina do envelope', () {
    final response = ApiResponse<List<String>>.fromJson(
      {
        'sucesso': true,
        'dados': ['a'],
        'paginacao': {'total': 40, 'pagina': 2, 'itensPorPagina': 20},
      },
      mapData: (raw) => (raw as List).cast<String>(),
    );
    final page = pageFrom(response);
    expect(page.total, 40);
    expect(page.hasMore, isFalse);
  });
}
