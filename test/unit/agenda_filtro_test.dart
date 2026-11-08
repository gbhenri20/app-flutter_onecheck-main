import 'package:flutter_test/flutter_test.dart';
import 'package:one_check/features/agenda/presentation/providers/agenda_filtro.dart';
import 'package:one_check/features/checklist/domain/checklist_models.dart';

AgendaItem _item({
  required String id,
  required String vistoriadorId,
  required String tipo,
  required String status,
  required String titulo,
  required String rua,
}) {
  return AgendaItem(
    checklist: Checklist(
      id: id,
      contratoId: 'c-$id',
      vistoriadorId: vistoriadorId,
      tipo: tipo,
      status: status,
    ),
    contrato: Contrato(
      id: 'c-$id',
      imovelId: 'i-$id',
      locatarioId: 'l',
      status: 'ativo',
    ),
    imovel: Imovel(
      id: 'i-$id',
      titulo: titulo,
      endereco: Endereco(rua: rua, cidade: 'São Paulo', estado: 'SP'),
    ),
  );
}

void main() {
  final itens = [
    _item(
      id: '1',
      vistoriadorId: 'joao',
      tipo: 'inicial',
      status: 'em_preenchimento',
      titulo: 'Apartamento Centro',
      rua: 'Rua das Flores',
    ),
    _item(
      id: '2',
      vistoriadorId: 'ana',
      tipo: 'encerramento',
      status: 'aceito',
      titulo: 'Casa Moema',
      rua: 'Rua Gaivota',
    ),
    _item(
      id: '3',
      vistoriadorId: 'ana',
      tipo: 'manutencao',
      status: 'pendente_aceite',
      titulo: 'Studio Pinheiros',
      rua: 'Rua dos Pinheiros',
    ),
  ];

  test('filtra por responsável, status, tipo e endereço', () {
    expect(
      filtrarAgenda(itens, const AgendaFiltro(vistoriadorId: 'ana')),
      hasLength(2),
    );
    expect(
      filtrarAgenda(itens, const AgendaFiltro(status: 'aceito')),
      hasLength(1),
    );
    expect(
      filtrarAgenda(itens, const AgendaFiltro(tipo: 'manutencao')),
      hasLength(1),
    );
    expect(
      filtrarAgenda(
        itens,
        const AgendaFiltro(busca: 'gaivota'),
        nomesVistoriador: const {'ana': 'Ana Vistoriadora'},
      ),
      hasLength(1),
    );
    expect(
      filtrarAgenda(
        itens,
        const AgendaFiltro(busca: 'ana vistoriadora'),
        nomesVistoriador: const {'ana': 'Ana Vistoriadora'},
      ),
      hasLength(2),
    );
  });
}
