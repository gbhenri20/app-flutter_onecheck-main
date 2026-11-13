import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../checklist/domain/checklist_models.dart';
import 'valor_extenso.dart';

class DadosContratoDocumento {
  const DadosContratoDocumento({
    required this.numero,
    required this.status,
    required this.nomeLocatario,
    required this.emitidoEm,
    this.cpfLocatario,
    this.imovelNome,
    this.imovelTipo,
    this.imovelTamanho,
    this.garagem = false,
    this.garagemVagas = 0,
    this.endereco,
    this.dataInicio,
    this.dataFim,
    this.valorMensal,
  });

  final String numero;
  final String status;
  final String nomeLocatario;
  final String? cpfLocatario;
  final String? imovelNome;
  final String? imovelTipo;
  final String? imovelTamanho;
  final bool garagem;
  final int garagemVagas;
  final Endereco? endereco;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final double? valorMensal;
  final DateTime emitidoEm;
}

String dataPorExtenso(DateTime data) {
  const meses = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  final local = data.toLocal();
  return '${local.day} de ${meses[local.month - 1]} de ${local.year}';
}

String dataCurta(DateTime? data) {
  if (data == null) return 'data não informada';
  final local = data.toLocal();
  final dia = local.day.toString().padLeft(2, '0');
  final mes = local.month.toString().padLeft(2, '0');
  return '$dia/$mes/${local.year}';
}

int mesesEntre(DateTime inicio, DateTime fim) {
  var meses = (fim.year - inicio.year) * 12 + fim.month - inicio.month;
  if (fim.day < inicio.day) meses -= 1;
  if (meses < 0) return 0;
  return meses;
}

String descricaoEndereco(Endereco? endereco) {
  if (endereco == null || !endereco.temLocalizacao) {
    return 'endereço não cadastrado no OneCheck';
  }
  final partes = <String>[
    endereco.linhaCompleta,
    if (endereco.complemento?.trim().isNotEmpty == true) endereco.complemento!.trim(),
    if (endereco.bloco?.trim().isNotEmpty == true) 'bloco ${endereco.bloco!.trim()}',
    if (endereco.andar?.trim().isNotEmpty == true) 'andar ${endereco.andar!.trim()}',
    if (endereco.cep?.trim().isNotEmpty == true) 'CEP ${endereco.cep!.trim()}',
  ];
  return partes.join(', ');
}

String? formatarCpf(String? cpf) {
  final texto = cpf?.trim() ?? '';
  if (texto.isEmpty) return null;
  final digitos = texto.replaceAll(RegExp(r'\D'), '');
  if (digitos.length != 11) return texto;
  return '${digitos.substring(0, 3)}.${digitos.substring(3, 6)}.${digitos.substring(6, 9)}-${digitos.substring(9)}';
}

List<(String, String)> clausulasDoContrato(DadosContratoDocumento dados) {
  final endereco = descricaoEndereco(dados.endereco);
  final tipo = dados.imovelTipo?.trim().isNotEmpty == true
      ? dados.imovelTipo!.trim()
      : 'imóvel';
  final nome = dados.imovelNome?.trim().isNotEmpty == true
      ? ', identificado no cadastro como "${dados.imovelNome!.trim()}"'
      : '';
  final detalhes = <String>[
    if (dados.imovelTamanho?.trim().isNotEmpty == true)
      'Área ou tipologia informada: ${dados.imovelTamanho!.trim()}.',
    if (dados.garagem)
      'O imóvel conta com garagem de ${dados.garagemVagas} vaga(s), que acompanha a locação.',
  ];

  final prazo = _textoPrazo(dados);
  final aluguel = _textoAluguel(dados);
  final cidade = dados.endereco?.cidade?.trim();
  final estado = dados.endereco?.estado?.trim();
  final foro = cidade != null && cidade.isNotEmpty
      ? 'da comarca de $cidade${estado != null && estado.isNotEmpty ? ', Estado de $estado' : ''}'
      : 'da comarca da situação do imóvel';

  return [
    (
      'CLÁUSULA PRIMEIRA — DO OBJETO',
      'O LOCADOR dá em locação ao LOCATÁRIO o $tipo$nome, situado em $endereco. '
          '${detalhes.join(' ')} '
          'O imóvel é locado no estado descrito na vistoria de entrada referida na cláusula quinta.',
    ),
    ('CLÁUSULA SEGUNDA — DO PRAZO', prazo),
    ('CLÁUSULA TERCEIRA — DO ALUGUEL', aluguel),
    (
      'CLÁUSULA QUARTA — DA DESTINAÇÃO',
      'O imóvel destina-se exclusivamente à residência do LOCATÁRIO. '
          'Mudança de destinação, cessão ou sublocação, no todo ou em parte, dependem de autorização escrita do LOCADOR.',
    ),
    (
      'CLÁUSULA QUINTA — DA VISTORIA',
      'A descrição do estado do imóvel na entrada e na saída é a do laudo de vistoria produzido no OneCheck e aceito pelas partes. '
          'Esse laudo integra o presente contrato para todos os fins. '
          'O desgaste decorrente do uso regular não caracteriza dano indenizável.',
    ),
    (
      'CLÁUSULA SEXTA — DAS OBRIGAÇÕES DO LOCATÁRIO',
      'O LOCATÁRIO obriga-se a pagar o aluguel no vencimento; a usar o imóvel com o cuidado devido; '
          'a conservar as instalações e a comunicar por escrito os defeitos cuja reparação caiba ao LOCADOR; '
          'a devolver o imóvel, ao término da locação, no estado em que o recebeu, conforme a vistoria de entrada, '
          'salvo as deteriorações naturais; e a franquear a vistoria de saída em dia e hora ajustados.',
    ),
    (
      'CLÁUSULA SÉTIMA — DAS OBRIGAÇÕES DO LOCADOR',
      'O LOCADOR obriga-se a entregar o imóvel em condições de servir ao uso residencial e a responder '
          'pelos vícios anteriores à locação e pelas reparações que a lei lhe atribui, ressalvado o que constar da vistoria de entrada.',
    ),
    (
      'CLÁUSULA OITAVA — DA RESCISÃO',
      'Quando o prazo da locação atingir trinta meses, o LOCATÁRIO poderá denunciá-la depois desse período, '
          'por escrito, com antecedência mínima de trinta dias. A desocupação antes do termo, fora das hipóteses legais, '
          'sujeita o LOCATÁRIO a multa compensatória proporcional ao tempo restante. '
          'A retomada pelo LOCADOR observa a Lei nº 8.245, de 18 de outubro de 1991.',
    ),
    (
      'CLÁUSULA NONA — DO FORO',
      'As partes elegem o foro $foro para dirimir qualquer questão deste contrato, '
          'com renúncia de qualquer outro, por mais privilegiado que seja.',
    ),
  ];
}

String _textoPrazo(DadosContratoDocumento dados) {
  final inicio = dados.dataInicio;
  final fim = dados.dataFim;
  if (inicio == null || fim == null) {
    return 'O prazo da locação é o lançado no cadastro deste contrato no OneCheck. '
        'Início: ${dataCurta(inicio)}. Término: ${dataCurta(fim)}.';
  }
  final meses = mesesEntre(inicio, fim);
  final quantidade = meses == 1 ? '1 (um) mês' : '$meses (${inteiroPorExtenso(meses)}) meses';
  return 'A locação tem início em ${dataCurta(inicio)} e término em ${dataCurta(fim)}, '
      'pelo prazo de $quantidade. '
      'A prorrogação, se houver, observa a Lei nº 8.245/1991.';
}

String _textoAluguel(DadosContratoDocumento dados) {
  final valor = dados.valorMensal;
  if (valor == null || valor <= 0) {
    return 'O valor do aluguel mensal não foi informado no cadastro e deverá constar de termo complementar assinado pelas partes, '
        'passando então a integrar este contrato.';
  }
  final dia = dados.dataInicio?.day ?? 5;
  final vencimento = dia > 28
      ? 'até o dia $dia de cada mês, ou no último dia do mês quando essa data não existir'
      : 'até o dia $dia de cada mês';
  return 'O aluguel mensal é de ${formatarReais(valor)} (${reaisPorExtenso(valor)}), '
      'vencendo-se $vencimento. '
      'O atraso no pagamento autoriza a cobrança da correção e dos demais encargos previstos em lei.';
}

Future<Uint8List> gerarContratoPdf(DadosContratoDocumento dados) async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
  final negrito = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
  final tema = pw.ThemeData.withFont(base: regular, bold: negrito);
  final documento = pw.Document();
  final clausulas = clausulasDoContrato(dados);
  final cidade = dados.endereco?.cidade?.trim();
  final local = cidade != null && cidade.isNotEmpty ? cidade : 'local do imóvel';

  documento.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(48, 40, 48, 52),
        theme: tema,
      ),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          'OneCheck  ·  Página ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ),
      build: (context) => [
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.green800, width: 2)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ONECHECK',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'CONTRATO DE LOCAÇÃO RESIDENCIAL',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Instrumento particular nº ${dados.numero}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 14),
        if (dados.status != 'ativo')
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.orange800),
            ),
            child: pw.Text(
              'Situação no OneCheck: ${_rotuloStatus(dados.status)}. '
              'Este documento reproduz os dados cadastrados e não reabre a locação.',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        pw.Text(
          'Pelo presente instrumento particular de locação, as partes abaixo qualificadas têm entre si justo e contratado o que segue, '
          'regido pela Lei nº 8.245, de 18 de outubro de 1991, e pelas cláusulas deste contrato.',
          textAlign: pw.TextAlign.justify,
          style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
        ),
        pw.SizedBox(height: 12),
        _rotulo('LOCADOR'),
        pw.Text(
          'Proprietário do imóvel descrito na cláusula primeira, que se identifica e assina ao final deste instrumento.',
          textAlign: pw.TextAlign.justify,
          style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
        ),
        pw.SizedBox(height: 10),
        _rotulo('LOCATÁRIO'),
        pw.Text(
          'Nome: ${dados.nomeLocatario}\nCPF: ${formatarCpf(dados.cpfLocatario) ?? 'não informado no cadastro'}',
          style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
        ),
        pw.SizedBox(height: 14),
        for (final clausula in clausulas) ...[
          pw.Text(
            clausula.$1,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            clausula.$2,
            textAlign: pw.TextAlign.justify,
            style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
          ),
          pw.SizedBox(height: 10),
        ],
        pw.Text(
          'E, por estarem justas e contratadas, as partes assinam este instrumento em duas vias de igual teor, '
          'na presença das testemunhas abaixo.',
          textAlign: pw.TextAlign.justify,
          style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          '$local, ${dataPorExtenso(dados.emitidoEm)}.',
          style: const pw.TextStyle(fontSize: 11),
        ),
        pw.SizedBox(height: 28),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _blocoAssinatura('LOCADOR', 'Nome, CPF ou CNPJ')),
            pw.SizedBox(width: 28),
            pw.Expanded(child: _blocoAssinatura('LOCATÁRIO', dados.nomeLocatario)),
          ],
        ),
        pw.SizedBox(height: 26),
        pw.Text(
          'TESTEMUNHAS',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _blocoAssinatura('1ª testemunha', 'Nome e CPF')),
            pw.SizedBox(width: 28),
            pw.Expanded(child: _blocoAssinatura('2ª testemunha', 'Nome e CPF')),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Text(
          'Documento gerado pelo OneCheck em ${dataCurta(dados.emitidoEm)} a partir do contrato cadastrado. '
          'A eficácia entre as partes depende da assinatura. Este arquivo não é registro em cartório.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700, lineSpacing: 2),
        ),
      ],
    ),
  );

  return documento.save();
}

String _rotuloStatus(String status) {
  switch (status) {
    case 'ativo':
      return 'ativo';
    case 'encerrado':
      return 'encerrado';
    case 'cancelado':
      return 'cancelado';
    default:
      return status;
  }
}

pw.Widget _rotulo(String texto) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Text(
      texto,
      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
    ),
  );
}

pw.Widget _blocoAssinatura(String papel, String nome) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(height: 1, color: PdfColors.black),
      pw.SizedBox(height: 4),
      pw.Text(papel, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      pw.Text(nome, style: const pw.TextStyle(fontSize: 9)),
    ],
  );
}
