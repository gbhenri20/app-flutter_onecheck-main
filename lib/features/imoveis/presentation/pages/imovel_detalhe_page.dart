import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/cep_field.dart';
import '../../../../core/widgets/endereco_mapa.dart';
import '../../../checklist/domain/checklist_models.dart';

class ImovelDetalhePage extends ConsumerWidget {
  const ImovelDetalhePage({super.key, required this.imovelId});

  final String imovelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imovelAsync = ref.watch(_imovelProvider(imovelId));
    final comodosAsync = ref.watch(_comodosProvider(imovelId));
    final canManage = ref.watch(authStateProvider).user?.isGestor == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Imóvel')),
      body: imovelAsync.when(
        loading: () => const OcLoading(),
        error: (e, _) => OcErrorView(
          message: e is AppException ? e.message : 'Imóvel indisponível',
          onRetry: () => ref.invalidate(_imovelProvider(imovelId)),
        ),
        data: (imovel) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OcInfoCard(
              title: imovel.nomeExibicao,
              subtitle:
                  '${imovel.tipo ?? '—'} · ${labelImovelStatus(imovel.status)}\n'
                  '${imovel.tamanho ?? 'Tamanho não informado'}'
                  '${imovel.garagem ? ' · Garagem (${imovel.garagemVagas})' : ''}',
            ),
            const SizedBox(height: 12),
            Text('Endereço', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(imovel.endereco?.linhaCompleta ?? 'Endereço não cadastrado'),
            if (imovel.endereco?.cep?.isNotEmpty == true)
              Text('CEP ${imovel.endereco!.cep}'),
            if (imovel.endereco != null && imovel.endereco!.temLocalizacao) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LocalizacaoPainel(
                  endereco: imovel.endereco!,
                  altura: 220,
                ),
              ),
            ],
            if (canManage) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _endereco(context, ref, imovel),
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: const Text('Atualizar endereço'),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Cômodos', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (canManage)
                  TextButton.icon(
                    onPressed: () => _comodo(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar'),
                  ),
              ],
            ),
            comodosAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(e is AppException ? e.message : 'Erro'),
              data: (comodos) {
                if (comodos.isEmpty) {
                  return const Text('Nenhum cômodo cadastrado.');
                }
                return Column(
                  children: [
                    for (final comodo in comodos)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(comodo.nomeExibicao),
                        subtitle: Text(comodo.tipo),
                        trailing: canManage
                            ? IconButton(
                                tooltip: 'Excluir cômodo',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _excluirComodo(context, ref, comodo),
                              )
                            : null,
                      ),
                  ],
                );
              },
            ),
            if (canManage) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _excluirImovel(context, ref),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Excluir imóvel'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _endereco(BuildContext context, WidgetRef ref, Imovel imovel) async {
    final rua = TextEditingController(text: imovel.endereco?.rua ?? '');
    final numero = TextEditingController(text: imovel.endereco?.numero ?? '');
    final cidade = TextEditingController(text: imovel.endereco?.cidade ?? '');
    final estado = TextEditingController(text: imovel.endereco?.estado ?? '');
    final cep = TextEditingController(text: imovel.endereco?.cep ?? '');
    final bairro = TextEditingController(text: imovel.endereco?.bairro ?? '');
    final cepKey = GlobalKey<CepFieldState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Endereço'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CepField(
                key: cepKey,
                cep: cep,
                rua: rua,
                bairro: bairro,
                cidade: cidade,
                estado: estado,
                numero: numero,
              ),
              TextField(controller: rua, decoration: const InputDecoration(labelText: 'Rua')),
              TextField(controller: numero, decoration: const InputDecoration(labelText: 'Número')),
              TextField(controller: bairro, decoration: const InputDecoration(labelText: 'Bairro')),
              TextField(controller: cidade, decoration: const InputDecoration(labelText: 'Cidade')),
              TextField(controller: estado, decoration: const InputDecoration(labelText: 'UF')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final cepOk = await cepKey.currentState?.garantir() ?? false;
              if (!cepOk || !nav.mounted) return;
              nav.pop(true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(imoveisRepositoryProvider).salvarEndereco(imovelId, {
          'rua': rua.text.trim(),
          'numero': numero.text.trim(),
          'bairro': bairro.text.trim(),
          'cidade': cidade.text.trim(),
          'estado': estado.text.trim(),
          'cep': cep.text.trim(),
        });
        ref.invalidate(_imovelProvider(imovelId));
      } on AppException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }
    rua.dispose();
    numero.dispose();
    cidade.dispose();
    estado.dispose();
    cep.dispose();
    bairro.dispose();
  }

  Future<void> _comodo(BuildContext context, WidgetRef ref) async {
    final tipo = TextEditingController();
    final descricao = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo cômodo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: tipo, decoration: const InputDecoration(labelText: 'Tipo')),
            TextField(controller: descricao, decoration: const InputDecoration(labelText: 'Descrição')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
        ],
      ),
    );
    if (ok == true && tipo.text.trim().isNotEmpty) {
      try {
        await ref.read(imoveisRepositoryProvider).criarComodo(
              imovelId: imovelId,
              tipo: tipo.text.trim(),
              descricao: descricao.text.trim(),
            );
        ref.invalidate(_comodosProvider(imovelId));
      } on AppException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }
    tipo.dispose();
    descricao.dispose();
  }

  Future<void> _excluirComodo(BuildContext context, WidgetRef ref, Comodo comodo) async {
    final ok = await _confirm(context, 'Excluir o cômodo ${comodo.nomeExibicao}?');
    if (!ok) return;
    try {
      await ref.read(imoveisRepositoryProvider).excluirComodo(
            imovelId: imovelId,
            comodoId: comodo.id,
          );
      ref.invalidate(_comodosProvider(imovelId));
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _excluirImovel(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(context, 'O imóvel será desativado. Deseja continuar?');
    if (!ok) return;
    try {
      await ref.read(imoveisRepositoryProvider).excluir(imovelId);
      if (context.mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

final _imovelProvider = FutureProvider.autoDispose.family<Imovel, String>((ref, id) {
  return ref.watch(imoveisRepositoryProvider).obter(id);
});

final _comodosProvider = FutureProvider.autoDispose.family<List<Comodo>, String>((ref, id) {
  return ref.watch(imoveisRepositoryProvider).comodos(id);
});

Future<bool> _confirm(BuildContext context, String message) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmar'),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
      ],
    ),
  );
  return ok == true;
}
