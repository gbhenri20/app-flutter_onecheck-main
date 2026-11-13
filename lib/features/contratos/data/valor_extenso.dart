const _unidades = [
  '',
  'um',
  'dois',
  'três',
  'quatro',
  'cinco',
  'seis',
  'sete',
  'oito',
  'nove',
  'dez',
  'onze',
  'doze',
  'treze',
  'quatorze',
  'quinze',
  'dezesseis',
  'dezessete',
  'dezoito',
  'dezenove',
];

const _dezenas = [
  '',
  '',
  'vinte',
  'trinta',
  'quarenta',
  'cinquenta',
  'sessenta',
  'setenta',
  'oitenta',
  'noventa',
];

const _centenas = [
  '',
  'cento',
  'duzentos',
  'trezentos',
  'quatrocentos',
  'quinhentos',
  'seiscentos',
  'setecentos',
  'oitocentos',
  'novecentos',
];

String _ate999(int n) {
  if (n <= 0) return '';
  if (n < 20) return _unidades[n];
  if (n < 100) {
    final dezena = n ~/ 10;
    final unidade = n % 10;
    if (unidade == 0) return _dezenas[dezena];
    return '${_dezenas[dezena]} e ${_unidades[unidade]}';
  }
  if (n == 100) return 'cem';
  final centena = n ~/ 100;
  final resto = n % 100;
  if (resto == 0) return _centenas[centena];
  return '${_centenas[centena]} e ${_ate999(resto)}';
}

/// Inteiro em português, de zero até a casa dos milhões.
String inteiroPorExtenso(int valor) {
  if (valor == 0) return 'zero';
  if (valor < 0) return 'menos ${inteiroPorExtenso(-valor)}';

  final milhoes = valor ~/ 1000000;
  final milhares = (valor % 1000000) ~/ 1000;
  final resto = valor % 1000;
  final partes = <String>[];

  if (milhoes == 1) {
    partes.add('um milhão');
  } else if (milhoes > 1) {
    partes.add('${_ate999(milhoes)} milhões');
  }
  if (milhares == 1) {
    partes.add('mil');
  } else if (milhares > 1) {
    partes.add('${_ate999(milhares)} mil');
  }
  if (resto > 0) partes.add(_ate999(resto));
  if (partes.length == 1) return partes.single;

  final ultimo = partes.removeLast();
  final ligaComE = resto > 0 && (resto < 100 || resto % 100 == 0);
  if (ligaComE) return '${partes.join(' ')} e $ultimo';
  return '${partes.join(' ')} $ultimo';
}

/// Valor monetário por extenso, em reais e centavos.
String reaisPorExtenso(double valor) {
  final centavosTotais = (valor * 100).round();
  final reais = centavosTotais ~/ 100;
  final centavos = centavosTotais % 100;
  final reaisTexto = inteiroPorExtenso(reais);
  final unidadeReais = reais == 1 ? 'real' : 'reais';
  if (centavos == 0) return '$reaisTexto $unidadeReais';
  final centavosTexto = inteiroPorExtenso(centavos);
  final unidadeCentavos = centavos == 1 ? 'centavo' : 'centavos';
  return '$reaisTexto $unidadeReais e $centavosTexto $unidadeCentavos';
}

String formatarReais(double valor) {
  final centavosTotais = (valor * 100).round();
  final reais = centavosTotais ~/ 100;
  final centavos = (centavosTotais % 100).toString().padLeft(2, '0');
  final grupos = reais.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      );
  return 'R\$ $grupos,$centavos';
}
