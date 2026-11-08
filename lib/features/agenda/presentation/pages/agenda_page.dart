import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../checklist/domain/checklist_models.dart';
import '../providers/agenda_filtro.dart';
import '../providers/agenda_providers.dart';

class AgendaPage extends ConsumerStatefulWidget {
  const AgendaPage({super.key});

  @override
  ConsumerState<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends ConsumerState<AgendaPage> {
  final _busca = TextEditingController();

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  void _setFiltro(AgendaFiltro filtro) {
    ref.read(agendaFiltroProvider.notifier).state = filtro;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(agendaProvider);
    final filtro = ref.watch(agendaFiltroProvider);
    final nomes = ref.watch(nomesVistoriadorProvider).valueOrNull ?? const {};
    final podeFiltrarResponsavel =
        ref.watch(authStateProvider).user?.isGestor == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda de vistorias'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => ref.invalidate(agendaProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: async.when(
        loading: () => const OcLoading(message: 'Carregando agenda...'),
        error: (e, _) {
          final msg = e is AppException ? e.message : 'Falha ao carregar agenda';
          return OcErrorView(
            message: msg,
            onRetry: () => ref.invalidate(agendaProvider),
          );
        },
        data: (items) {
          final visiveis = filtrarAgenda(items, filtro, nomesVistoriador: nomes);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(agendaProvider);
              await ref.read(agendaProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _busca,
                  decoration: const InputDecoration(
                    labelText: 'Buscar imóvel ou endereço',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (value) => _setFiltro(filtro.copyWith(busca: value)),
                ),
                const SizedBox(height: 12),
                _Chips(
                  titulo: 'Status',
                  selecionado: filtro.status,
                  opcoes: const [
                    ('em_preenchimento', 'Em andamento'),
                    ('pendente_aceite', 'Aguardando'),
                    ('aceito', 'Concluída'),
                    ('rejeitado', 'Rejeitada'),
                  ],
                  onSelected: (value) => _setFiltro(
                    filtro.copyWith(
                      status: value,
                      limparStatus: value == null || value == filtro.status,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _Chips(
                  titulo: 'Tipo',
                  selecionado: filtro.tipo,
                  opcoes: const [
                    ('inicial', 'Entrada'),
                    ('encerramento', 'Saída'),
                    ('manutencao', 'Manutenção'),
                  ],
                  onSelected: (value) => _setFiltro(
                    filtro.copyWith(
                      tipo: value,
                      limparTipo: value == null || value == filtro.tipo,
                    ),
                  ),
                ),
                if (podeFiltrarResponsavel && nomes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: filtro.vistoriadorId,
                    decoration: const InputDecoration(
                      labelText: 'Responsável',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos os vistoriadores'),
                      ),
                      for (final entry in nomes.entries)
                        DropdownMenuItem<String?>(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                    ],
                    onChanged: (value) => _setFiltro(
                      filtro.copyWith(
                        vistoriadorId: value,
                        limparVistoriador: value == null,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (items.isEmpty)
                  const OcEmptyState(
                    title: 'Nenhuma vistoria na agenda',
                    subtitle:
                        'Quando houver checklists atribuídos, eles aparecerão aqui.',
                    icon: Icons.event_available_outlined,
                  )
                else if (visiveis.isEmpty)
                  const OcEmptyState(
                    title: 'Nenhuma vistoria neste filtro',
                    subtitle: 'Ajuste a busca, o status ou o tipo.',
                    icon: Icons.filter_alt_off_outlined,
                  )
                else ...[
                  Text(
                    '${visiveis.length} vistoria(s)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final item in visiveis)
                    _AgendaTile(
                      item: item,
                      vistoriador: nomes[item.checklist.vistoriadorId],
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({
    required this.titulo,
    required this.selecionado,
    required this.opcoes,
    required this.onSelected,
  });

  final String titulo;
  final String? selecionado;
  final List<(String, String)> opcoes;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final opcao in opcoes)
              FilterChip(
                label: Text(opcao.$2),
                selected: selecionado == opcao.$1,
                onSelected: (_) => onSelected(
                  selecionado == opcao.$1 ? null : opcao.$1,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AgendaTile extends StatelessWidget {
  const _AgendaTile({required this.item, this.vistoriador});

  final AgendaItem item;
  final String? vistoriador;

  @override
  Widget build(BuildContext context) {
    final ck = item.checklist;
    final imovel = item.imovel;
    final data = item.agendamento?.dataAgendada ?? ck.dataVistoria;
    final editable = ck.podeEditar;
    final detalhes = <String>[
      if (imovel != null)
        [
          if (imovel.tipo != null) imovel.tipo,
          if (imovel.tamanho != null) imovel.tamanho,
          if (imovel.garagem) '${imovel.garagemVagas} vaga(s)',
        ].whereType<String>().join(' · '),
      imovel?.endereco?.linhaCompleta ?? 'Endereço indisponível',
      if (imovel?.endereco?.complemento?.isNotEmpty == true)
        imovel!.endereco!.complemento!,
      '${labelTipoVistoria(ck.tipo)} · ${formatDateTime(data)}',
      if (vistoriador != null) 'Responsável: $vistoriador',
      if (item.agendamento?.observacao?.isNotEmpty == true)
        item.agendamento!.observacao!,
    ].where((linha) => linha.isNotEmpty).join('\n');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OcInfoCard(
        title: imovel?.nomeExibicao ?? 'Contrato ${shortId(item.contrato.id)}',
        subtitle: detalhes,
        trailing: StatusChip(status: ck.status),
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          child: Icon(
            editable ? Icons.assignment_outlined : Icons.lock_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        onTap: () {
          if (!editable) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Esta vistoria já foi enviada e não pode ser reaberta para edição.',
                ),
              ),
            );
            context.push('/vistoria/${ck.id}/revisao');
            return;
          }
          context.push('/vistoria/${ck.id}');
        },
      ),
    );
  }
}
