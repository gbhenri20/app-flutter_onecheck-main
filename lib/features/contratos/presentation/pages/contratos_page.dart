import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/paged.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../checklist/domain/checklist_models.dart';
import '../../../usuarios/domain/usuario_operacional.dart';

final contratosProvider =
    FutureProvider.autoDispose<PageResult<Contrato>>((ref) {
  return ref.watch(contratosRepositoryProvider).listar(porPagina: 50);
});

class ContratosPage extends ConsumerWidget {
  const ContratosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(contratosProvider);
    final canManage = ref.watch(authStateProvider).user?.isGestor == true;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contratos'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(contratosProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _criar(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Novo contrato'),
            )
          : null,
      body: async.when(
        loading: () => const OcLoading(),
        error: (e, _) => OcErrorView(
          message: e is AppException ? e.message : 'Erro ao listar contratos',
          onRetry: () => ref.invalidate(contratosProvider),
        ),
        data: (page) {
          if (page.items.isEmpty) {
            return const OcEmptyState(
              title: 'Nenhum contrato',
              subtitle: 'Os contratos vinculados ao seu perfil aparecerão aqui.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: page.items.length,
            itemBuilder: (context, index) {
              final contrato = page.items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OcInfoCard(
                  title: 'Contrato ${shortId(contrato.id)}',
                  subtitle:
                      '${labelContratoStatus(contrato.status)}\n'
                      '${formatDate(contrato.dataInicio)} — ${formatDate(contrato.dataFim)}',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/contratos/${contrato.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _criar(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final imoveis = await ref.read(imoveisRepositoryProvider).listar(
            porPagina: 100,
            status: 'disponivel',
          );
      final locatarios = await ref.read(usuariosRepositoryProvider).listarOperacionais(
            role: 'locatario',
          );
      if (!navigator.mounted) return;
      if (imoveis.items.isEmpty || locatarios.items.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('É preciso um imóvel disponível e um locatário cadastrado.'),
          ),
        );
        return;
      }
      Imovel? imovel = imoveis.items.first;
      UsuarioOperacional? locatario = locatarios.items.first;
      final inicio = TextEditingController();
      final fim = TextEditingController();
      final valor = TextEditingController();
      final ok = await showDialog<bool>(
        context: navigator.context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Novo contrato'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Imovel>(
                    key: ValueKey(imovel?.id),
                    initialValue: imovel,
                    items: [
                      for (final item in imoveis.items)
                        DropdownMenuItem(value: item, child: Text(item.nomeExibicao)),
                    ],
                    onChanged: (value) => setLocal(() => imovel = value),
                    decoration: const InputDecoration(labelText: 'Imóvel disponível'),
                  ),
                  DropdownButtonFormField<UsuarioOperacional>(
                    key: ValueKey(locatario?.id),
                    initialValue: locatario,
                    items: [
                      for (final item in locatarios.items)
                        DropdownMenuItem(value: item, child: Text(item.nome)),
                    ],
                    onChanged: (value) => setLocal(() => locatario = value),
                    decoration: const InputDecoration(labelText: 'Locatário'),
                  ),
                  TextField(
                    controller: inicio,
                    decoration: const InputDecoration(labelText: 'Início (AAAA-MM-DD)'),
                  ),
                  TextField(
                    controller: fim,
                    decoration: const InputDecoration(labelText: 'Fim (AAAA-MM-DD)'),
                  ),
                  TextField(
                    controller: valor,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Valor mensal'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
            ],
          ),
        ),
      );
      if (ok == true && imovel != null && locatario != null) {
        await ref.read(contratosRepositoryProvider).criar(
              imovelId: imovel!.id,
              locatarioId: locatario!.id,
              dataInicio: inicio.text.trim(),
              dataFim: fim.text.trim(),
              valorMensal: double.tryParse(valor.text.replaceAll(',', '.')),
            );
        ref.invalidate(contratosProvider);
      }
      inicio.dispose();
      fim.dispose();
      valor.dispose();
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
