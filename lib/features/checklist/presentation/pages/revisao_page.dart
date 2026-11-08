import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/files/file_saver.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../providers/checklist_providers.dart';

class RevisaoPage extends ConsumerStatefulWidget {
  const RevisaoPage({super.key, required this.checklistId});

  final String checklistId;

  @override
  ConsumerState<RevisaoPage> createState() => _RevisaoPageState();
}

class _RevisaoPageState extends ConsumerState<RevisaoPage> {
  bool _submitting = false;

  Future<void> _submeter() async {
    final gestor = ref.read(authStateProvider).user?.roleRaw == 'gestor';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(gestor ? 'Enviar para aceite' : 'Confirmar envio'),
        content: const Text(
          'Após o envio, a vistoria não poderá ser editada. '
          'A operação só é concluída quando a API confirmar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _submitting = true);
    try {
      final repo = ref.read(checklistRepositoryProvider);
      if (gestor) {
        await repo.enviarParaAceite(widget.checklistId);
      } else {
        await repo.submeter(widget.checklistId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vistoria enviada com sucesso')),
      );
      context.go('/agenda');
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _acaoEnvio() {
    if (ref.read(authStateProvider).user?.roleRaw == 'gestor') {
      return 'Enviar para aceite';
    }
    return 'Enviar vistoria';
  }

  Future<void> _pdf() async {
    try {
      final bytes = await ref
          .read(checklistRepositoryProvider)
          .baixarPdf(widget.checklistId);
      await saveBytes(
        bytes: bytes,
        filename: 'laudo-${widget.checklistId}.pdf',
        mimeType: 'application/pdf',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laudo baixado.')),
      );
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(checklistDetailProvider(widget.checklistId));
    final catalogo = ref.watch(itensCatalogoProvider).valueOrNull ?? const [];
    final nomeItem = {
      for (final c in catalogo) c.id: c.nome,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Revisão da vistoria')),
      body: async.when(
        loading: () => const OcLoading(),
        error: (e, _) => OcErrorView(
          message: e is AppException ? e.message : 'Erro',
          onRetry: () =>
              ref.invalidate(checklistDetailProvider(widget.checklistId)),
        ),
        data: (ck) {
          final preenchidos = ck.itensPreenchidos;
          final porComodo = <String, List<dynamic>>{};
          for (final item in ck.itens) {
            porComodo.putIfAbsent(item.comodoId, () => []).add(item);
          }
          final avisos = <String>[];
          if (preenchidos == 0) {
            avisos.add(
              'É necessário preencher ao menos um item para enviar (regra da API).',
            );
          }
          for (final comodo in ck.comodos) {
            final itens = porComodo[comodo.id] ?? [];
            if (itens.isEmpty) {
              avisos.add('Cômodo "${comodo.nomeExibicao}" sem itens preenchidos.');
            }
          }

          return Column(
            children: [
              if (_submitting) const LinearProgressIndicator(minHeight: 3),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    OcInfoCard(
                      title: labelTipoVistoria(ck.tipo),
                      subtitle:
                          'Status: ${labelChecklistStatus(ck.status)}\n'
                          'Itens preenchidos: $preenchidos',
                      trailing: StatusChip(status: ck.status),
                    ),
                    if (avisos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ...avisos.map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(a)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ...ck.comodos.map((comodo) {
                      final itens = ck.itens
                          .where((i) => i.comodoId == comodo.id)
                          .toList();
                      return ExpansionTile(
                        title: Text(comodo.nomeExibicao),
                        subtitle: Text(
                          '${itens.where((i) => i.preenchido).length} preenchidos',
                        ),
                        children: itens.isEmpty
                            ? [
                                const ListTile(
                                  title: Text('Nenhum item neste cômodo'),
                                ),
                              ]
                            : itens
                                .map(
                                  (i) => ListTile(
                                    title: Text(
                                      nomeItem[i.itemVistoriaId] ??
                                          i.itemVistoriaId,
                                    ),
                                    subtitle: Text(
                                      '${labelEstadoItem(i.estado)}'
                                      '${i.observacao?.isNotEmpty == true ? ' · ${i.observacao}' : ''}'
                                      '${i.fotos.isNotEmpty ? ' · ${i.fotos.length} foto(s)' : ''}',
                                    ),
                                  ),
                                )
                                .toList(),
                      );
                    }),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (ck.podeEditar) ...[
                        OutlinedButton(
                          onPressed: () => context.pop(),
                          child: const Text('Voltar ao checklist'),
                        ),
                        const SizedBox(height: 8),
                        OcPrimaryButton(
                          label: _acaoEnvio(),
                          loading: _submitting,
                          icon: Icons.send_outlined,
                          onPressed: preenchidos == 0 ? null : _submeter,
                        ),
                      ] else
                        Text(
                          'Vistoria em status "${labelChecklistStatus(ck.status)}" — edição bloqueada.',
                          textAlign: TextAlign.center,
                        ),
                      if (ref.watch(authStateProvider).user?.isVistoriador != true) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _pdf(),
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('Baixar laudo PDF'),
                        ),
                      ],
                      if (ck.aceite != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Registro de aceite: ${ck.aceite!.status}'
                          '${ck.aceite!.motivoRejeicao != null ? ' — ${ck.aceite!.motivoRejeicao}' : ''}'
                          '${ck.aceite!.createdAt != null ? '\n${formatDateTime(ck.aceite!.createdAt)}' : ''}',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
