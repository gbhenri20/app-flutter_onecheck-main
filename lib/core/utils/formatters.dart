
import 'package:intl/intl.dart';

final _date = DateFormat('dd/MM/yyyy', 'pt_BR');
final _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

String formatDate(DateTime? value) {
  if (value == null) return '—';
  return _date.format(value.toLocal());
}

String formatDateTime(DateTime? value) {
  if (value == null) return '—';
  return _dateTime.format(value.toLocal());
}

DateTime? parseApiDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    return DateTime.parse(raw);
  } catch (_) {
    return null;
  }
}

String labelChecklistStatus(String status) {
  switch (status) {
    case 'em_preenchimento':
      return 'Em preenchimento';
    case 'pendente_aceite':
      return 'Aguardando aprovação';
    case 'aceito':
      return 'Aceita';
    case 'rejeitado':
      return 'Rejeitada';
    case 'finalizado':
      return 'Finalizada';
    default:
      return status;
  }
}

String labelEstadoItem(String? estado) {
  switch (estado) {
    case 'otimo':
      return 'Ótimo';
    case 'bom':
      return 'Bom';
    case 'regular':
      return 'Regular';
    case 'ruim':
      return 'Ruim';
    default:
      return 'Pendente';
  }
}

String labelTipoVistoria(String tipo) {
  switch (tipo) {
    case 'inicial':
      return 'Entrada';
    case 'encerramento':
      return 'Saída';
    case 'manutencao':
      return 'Manutenção';
    default:
      return tipo;
  }
}

String labelRole(String role) {
  switch (role) {
    case 'admin':
      return 'Administrador';
    case 'gestor':
      return 'Gestor';
    case 'vistoriador':
      return 'Vistoriador';
    case 'locatario':
      return 'Locatário';
    default:
      return role;
  }
}

String shortId(String id) {
  if (id.length <= 8) return id;
  return '${id.substring(0, 8)}…';
}

String labelContratoStatus(String status) {
  switch (status) {
    case 'ativo':
      return 'Ativo';
    case 'encerrado':
      return 'Encerrado';
    case 'cancelado':
      return 'Cancelado';
    default:
      return status;
  }
}

String labelImovelStatus(String? status) {
  switch (status) {
    case 'disponivel':
      return 'Disponível';
    case 'locado':
      return 'Locado';
    default:
      return status ?? '—';
  }
}

String labelPrioridade(String? prioridade) {
  switch (prioridade) {
    case 'normal':
      return 'Normal';
    case 'alta':
      return 'Alta';
    case 'urgente':
      return 'Urgente';
    default:
      return prioridade ?? 'Normal';
  }
}

String labelProblemaStatus(String status) {
  switch (status) {
    case 'aberto':
      return 'Aberto';
    case 'em_andamento':
      return 'Em andamento';
    case 'em_analise':
      return 'Em análise';
    case 'resolvido':
      return 'Resolvido';
    case 'fechado':
      return 'Fechado';
    default:
      return status;
  }
}
