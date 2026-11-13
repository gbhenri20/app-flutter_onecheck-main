import 'package:flutter_test/flutter_test.dart';
import 'package:one_check/features/checklist/domain/checklist_models.dart';
import 'package:one_check/features/contratos/data/contrato_pdf.dart';
import 'package:one_check/features/contratos/data/valor_extenso.dart';

void main() {
  test('escreve reais e centavos por extenso', () {
    expect(reaisPorExtenso(1), 'um real');
    expect(reaisPorExtenso(2), 'dois reais');
    expect(reaisPorExtenso(1500), 'mil e quinhentos reais');
    expect(
      reaisPorExtenso(2500.10),
      'dois mil e quinhentos reais e dez centavos',
    );
    expect(reaisPorExtenso(1.01), 'um real e um centavo');
    expect(formatarReais(1500), r'R$ 1.500,00');
  });

  test('cláusulas usam endereço, prazo e aluguel do contrato', () {
    final clausulas = clausulasDoContrato(
      DadosContratoDocumento(
        numero: 'abc-123',
        status: 'ativo',
        nomeLocatario: 'Pedro Lima',
        emitidoEm: DateTime(2026, 11, 13),
        imovelTipo: 'apartamento',
        imovelNome: 'Apto 12',
        endereco: const Endereco(
          rua: 'Rua dos Pinheiros',
          numero: '800',
          bairro: 'Pinheiros',
          cidade: 'São Paulo',
          estado: 'SP',
          cep: '05422-001',
        ),
        dataInicio: DateTime(2026, 1, 10),
        dataFim: DateTime(2027, 1, 10),
        valorMensal: 1800,
      ),
    );
    final texto = clausulas.map((item) => item.$2).join('\n');
    expect(texto, contains('Rua dos Pinheiros'));
    expect(texto, contains('12 (doze) meses'));
    expect(texto, contains('R\$ 1.800,00'));
    expect(texto, contains('mil e oitocentos reais'));
    expect(texto, contains('comarca de São Paulo'));
  });

  test('o arquivo gerado é um PDF', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final bytes = await gerarContratoPdf(
      DadosContratoDocumento(
        numero: 'abc-123',
        status: 'ativo',
        nomeLocatario: 'Pedro Lima',
        emitidoEm: DateTime(2026, 11, 13),
        endereco: const Endereco(
          rua: 'Rua A',
          cidade: 'São Paulo',
          estado: 'SP',
        ),
        dataInicio: DateTime(2026, 1, 10),
        dataFim: DateTime(2026, 7, 10),
        valorMensal: 900,
      ),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length > 1000, isTrue);
  });
}
