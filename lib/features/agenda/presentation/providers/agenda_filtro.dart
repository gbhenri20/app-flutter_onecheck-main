import '../../../checklist/domain/checklist_models.dart';

class AgendaFiltro {
  const AgendaFiltro({
    this.busca = '',
    this.status,
    this.tipo,
    this.vistoriadorId,
  });

  final String busca;
  final String? status;
  final String? tipo;
  final String? vistoriadorId;

  AgendaFiltro copyWith({
    String? busca,
    String? status,
    String? tipo,
    String? vistoriadorId,
    bool limparStatus = false,
    bool limparTipo = false,
    bool limparVistoriador = false,
  }) {
    return AgendaFiltro(
      busca: busca ?? this.busca,
      status: limparStatus ? null : (status ?? this.status),
      tipo: limparTipo ? null : (tipo ?? this.tipo),
      vistoriadorId:
          limparVistoriador ? null : (vistoriadorId ?? this.vistoriadorId),
    );
  }
}

List<AgendaItem> filtrarAgenda(
  List<AgendaItem> items,
  AgendaFiltro filtro, {
  Map<String, String> nomesVistoriador = const {},
}) {
  final termo = filtro.busca.trim().toLowerCase();
  return items.where((item) {
    final ck = item.checklist;
    if (filtro.status != null && ck.status != filtro.status) return false;
    if (filtro.tipo != null && ck.tipo != filtro.tipo) return false;
    if (filtro.vistoriadorId != null && ck.vistoriadorId != filtro.vistoriadorId) {
      return false;
    }
    if (termo.isEmpty) return true;
    final imovel = item.imovel;
    final nome = nomesVistoriador[ck.vistoriadorId] ?? '';
    final alvo = [
      imovel?.nomeExibicao,
      imovel?.codigo,
      imovel?.endereco?.linhaCompleta,
      imovel?.endereco?.complemento,
      imovel?.tipo,
      item.agendamento?.observacao,
      nome,
    ].whereType<String>().join(' ').toLowerCase();
    return alvo.contains(termo);
  }).toList();
}
