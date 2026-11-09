import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../checklist/domain/checklist_models.dart';
import '../../../usuarios/domain/usuario_operacional.dart';

class ContratoDetalhePage extends ConsumerWidget {
  const ContratoDetalhePage({super.key, required this.contratoId});

  final String contratoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contratoAsync = ref.watch(_contratoProvider(contratoId));
    final agendaAsync = ref.watch(_agendaContratoProvider(contratoId));
    final checksAsync = ref.watch(_checksProvider(contratoId));
    final user = ref.watch(authStateProvider).user;
    final canManage = user?.isGestor == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Contrato')),
      body: contratoAsync.when(
        loading: () => const OcLoading(),
        error: (e, _) => OcErrorView(
          message: e is AppException ? e.message : 'Contrato indisponível',
          onRetry: () => ref.invalidate(_contratoProvider(contratoId)),
        ),
        data: (contrato) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OcInfoCard(
              title: labelContratoStatus(contrato.status),
              subtitle:
                  '${formatDate(contrato.dataInicio)} — ${formatDate(contrato.dataFim)}\n'
                  'Imóvel ${shortId(contrato.imovelId)} · Locatário ${shortId(contrato.locatarioId)}'
                  '${contrato.valorMensal != null ? '\nR\$ ${contrato.valorMensal!.toStringAsFixed(2)}' : ''}',
            ),
            if (canManage && contrato.status == 'ativo') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _acao(context, ref, encerrar: true),
                      child: const Text('Encerrar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _acao(context, ref, encerrar: false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Agendamentos', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (canManage && contrato.status == 'ativo')
                  TextButton(
                    onPressed: () => _agendar(context, ref),
                    child: const Text('Agendar'),
                  ),
              ],
            ),
            const Text(
              'A API não tem status no agendamento. Cancelar remove o registro. '
              'Não existe GET /agendamentos global: a lista é deste contrato.',
            ),
            const SizedBox(height: 8),
            agendaAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(e is AppException ? e.message : 'Erro'),
              data: (items) {
                final filtrados = _filtrar(ref, items);
                if (filtrados.isEmpty) return const Text('Nenhum agendamento neste filtro.');
                return Column(
                  children: [
                    for (final ag in filtrados)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(labelTipoVistoria(ag.tipo)),
                        subtitle: Text(
                          '${formatDateTime(ag.dataAgendada)}'
                          '${ag.observacao != null ? '\n${ag.observacao}' : ''}',
                        ),
                        trailing: canManage
                            ? IconButton(
                                tooltip: 'Cancelar agendamento',
                                icon: const Icon(Icons.event_busy),
                                onPressed: () => _cancelarAgendamento(context, ref, ag),
                              )
                            : null,
                        onTap: canManage ? () => _editar(context, ref, ag) : null,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: ref.watch(_tipoFiltroProvider) == null,
                  onSelected: (_) => ref.read(_tipoFiltroProvider.notifier).state = null,
                ),
                FilterChip(
                  label: const Text('Entrada'),
                  selected: ref.watch(_tipoFiltroProvider) == 'inicial',
                  onSelected: (_) => ref.read(_tipoFiltroProvider.notifier).state = 'inicial',
                ),
                FilterChip(
                  label: const Text('Saída'),
                  selected: ref.watch(_tipoFiltroProvider) == 'encerramento',
                  onSelected: (_) =>
                      ref.read(_tipoFiltroProvider.notifier).state = 'encerramento',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Vistorias', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (canManage)
                  TextButton(
                    onPressed: () => _checklist(context, ref),
                    child: const Text('Criar checklist'),
                  ),
              ],
            ),
            checksAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(e is AppException ? e.message : 'Erro'),
              data: (items) {
                if (items.isEmpty) return const Text('Nenhuma vistoria neste contrato.');
                return Column(
                  children: [
                    for (final ck in items)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(labelTipoVistoria(ck.tipo)),
                        subtitle: Text(labelChecklistStatus(ck.status)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          ck.podeEditar ? '/vistoria/${ck.id}' : '/vistoria/${ck.id}/revisao',
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Agendamento> _filtrar(WidgetRef ref, List<Agendamento> items) {
    final tipo = ref.watch(_tipoFiltroProvider);
    return [
      for (final item in items)
        if (tipo == null || item.tipo == tipo) item,
    ];
  }

  Future<void> _acao(BuildContext context, WidgetRef ref, {required bool encerrar}) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(encerrar ? 'Encerrar contrato' : 'Cancelar contrato'),
        content: Text(
          encerrar
              ? 'O imóvel volta a ficar disponível. Confirmar encerramento?'
              : 'O contrato será cancelado e o imóvel liberado. Confirmar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final repo = ref.read(contratosRepositoryProvider);
      if (encerrar) {
        await repo.encerrar(contratoId);
      } else {
        await repo.cancelar(contratoId);
      }
      ref.invalidate(_contratoProvider(contratoId));
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _agendar(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final quando = await _pickFuture(navigator.context);
    if (quando == null || !navigator.mounted) return;
    var tipo = 'inicial';
    final obs = TextEditingController();
    final ok = await showDialog<bool>(
      context: navigator.context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Novo agendamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey('ag-$tipo'),
                initialValue: tipo,
                items: const [
                  DropdownMenuItem(value: 'inicial', child: Text('Entrada')),
                  DropdownMenuItem(value: 'encerramento', child: Text('Saída')),
                ],
                onChanged: (value) => setLocal(() => tipo = value ?? 'inicial'),
              ),
              TextField(
                controller: obs,
                decoration: const InputDecoration(labelText: 'Observação'),
              ),
              Text(formatDateTime(quando)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (ok == true) {
      try {
        await ref.read(contratosRepositoryProvider).criarAgendamento(
              contratoId: contratoId,
              tipo: tipo,
              dataAgendada: quando.toIso8601String(),
              observacao: obs.text.trim(),
            );
        ref.invalidate(_agendaContratoProvider(contratoId));
      } on AppException catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
    obs.dispose();
  }

  Future<void> _editar(BuildContext context, WidgetRef ref, Agendamento ag) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final quando = await _pickFuture(navigator.context);
    if (quando == null) return;
    try {
      await ref.read(contratosRepositoryProvider).atualizarAgendamento(
            agendamentoId: ag.id,
            dataAgendada: quando.toIso8601String(),
          );
      ref.invalidate(_agendaContratoProvider(contratoId));
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _cancelarAgendamento(
    BuildContext context,
    WidgetRef ref,
    Agendamento ag,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar agendamento'),
        content: const Text('O registro será removido. A API não guarda um status de cancelado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remover')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(contratosRepositoryProvider).cancelarAgendamento(ag.id);
      ref.invalidate(_agendaContratoProvider(contratoId));
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _checklist(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final vistoriadores = await ref.read(usuariosRepositoryProvider).listarOperacionais(
          role: 'vistoriador',
        );
    if (!navigator.mounted) return;
    if (vistoriadores.items.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Cadastre um vistoriador antes de criar o checklist.')),
      );
      return;
    }
    UsuarioOperacional? vistoriador = vistoriadores.items.first;
    var tipo = 'inicial';
    final ok = await showDialog<bool>(
      context: navigator.context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Novo checklist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey('ck-$tipo'),
                initialValue: tipo,
                items: const [
                  DropdownMenuItem(value: 'inicial', child: Text('Entrada')),
                  DropdownMenuItem(value: 'encerramento', child: Text('Saída')),
                ],
                onChanged: (value) => setLocal(() => tipo = value ?? 'inicial'),
              ),
              DropdownButtonFormField<UsuarioOperacional>(
                key: ValueKey(vistoriador?.id),
                initialValue: vistoriador,
                items: [
                  for (final item in vistoriadores.items)
                    DropdownMenuItem(value: item, child: Text(item.nome)),
                ],
                onChanged: (value) => setLocal(() => vistoriador = value),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Criar')),
          ],
        ),
      ),
    );
    if (ok == true && vistoriador != null) {
      try {
        await ref.read(checklistRepositoryProvider).criar(
              contratoId: contratoId,
              tipo: tipo,
              vistoriadorId: vistoriador!.id,
            );
        ref.invalidate(_checksProvider(contratoId));
      } on AppException catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

final _tipoFiltroProvider = StateProvider<String?>((ref) => null);

final _contratoProvider = FutureProvider.autoDispose.family<Contrato, String>((ref, id) {
  return ref.watch(contratosRepositoryProvider).obter(id);
});

final _agendaContratoProvider =
    FutureProvider.autoDispose.family<List<Agendamento>, String>((ref, id) {
  return ref.watch(contratosRepositoryProvider).agendamentos(id);
});

final _checksProvider =
    FutureProvider.autoDispose.family<List<Checklist>, String>((ref, id) {
  return ref.watch(contratosRepositoryProvider).checklists(id);
});

Future<DateTime?> _pickFuture(BuildContext context) async {
  final navigator = Navigator.of(context);
  final now = DateTime.now();
  final date = await showDatePicker(
    context: navigator.context,
    firstDate: now,
    lastDate: DateTime(now.year + 5),
  );
  if (date == null || !navigator.mounted) return null;
  final time = await showTimePicker(
    context: navigator.context,
    initialTime: TimeOfDay.now(),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
