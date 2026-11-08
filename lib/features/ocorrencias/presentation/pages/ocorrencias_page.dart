import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../checklist/domain/checklist_models.dart';
import '../../domain/problema.dart';

final ocorrenciasProvider = FutureProvider.autoDispose<List<Problema>>((ref) async {
  final contratos = await ref.watch(contratosRepositoryProvider).listar(porPagina: 50);
  final repo = ref.watch(problemasRepositoryProvider);
  final all = <Problema>[];
  for (final contrato in contratos.items) {
    try {
      all.addAll(await repo.listByContrato(contrato.id));
    } on AppException {
      continue;
    }
  }
  return all;
});

class OcorrenciasPage extends ConsumerWidget {
  const OcorrenciasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ocorrenciasProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ocorrências')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nova(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: async.when(
        loading: () => const OcLoading(),
        error: (e, _) => OcErrorView(
          message: e is AppException ? e.message : 'Erro ao carregar ocorrências',
          onRetry: () => ref.invalidate(ocorrenciasProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const OcEmptyState(
              title: 'Nenhuma ocorrência',
              subtitle: 'Registre um problema em um contrato ativo.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final problema = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OcInfoCard(
                  title: problema.titulo,
                  subtitle:
                      '${labelProblemaStatus(problema.status)} · ${labelPrioridade(problema.prioridade)}\n'
                      '${problema.descricao ?? ''}',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/ocorrencias/${problema.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> _nova(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final contratos = await ref.read(contratosRepositoryProvider).listar(porPagina: 50);
  final ativos = contratos.items.where((c) => c.status == 'ativo').toList();
  if (!navigator.mounted) return;
  if (ativos.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Nenhum contrato ativo para registrar ocorrência.')),
    );
    return;
  }
  Contrato contrato = ativos.first;
  var prioridade = 'normal';
  final titulo = TextEditingController();
  final descricao = TextEditingController();
  final ok = await showDialog<bool>(
    context: navigator.context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: const Text('Nova ocorrência'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Contrato>(
                key: ValueKey(contrato.id),
                initialValue: contrato,
                items: [
                  for (final item in ativos)
                    DropdownMenuItem(
                      value: item,
                      child: Text('Contrato ${shortId(item.id)}'),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setLocal(() => contrato = value);
                },
                decoration: const InputDecoration(labelText: 'Contrato'),
              ),
              TextField(
                controller: titulo,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: descricao,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              DropdownButtonFormField<String>(
                key: ValueKey(prioridade),
                initialValue: prioridade,
                decoration: const InputDecoration(labelText: 'Prioridade'),
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'alta', child: Text('Alta')),
                  DropdownMenuItem(value: 'urgente', child: Text('Urgente')),
                ],
                onChanged: (value) => setLocal(() => prioridade = value ?? 'normal'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Registrar')),
        ],
      ),
    ),
  );
  if (ok != true) {
    titulo.dispose();
    descricao.dispose();
    return;
  }
  if (titulo.text.trim().isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Informe o título.')),
    );
    titulo.dispose();
    descricao.dispose();
    return;
  }
  try {
    Uint8List? foto;
    String? nome;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file != null) {
      final raw = await file.readAsBytes();
      final compressed = await const ImageCompressor().compress(
        bytes: raw,
        filename: file.name,
      );
      foto = compressed.bytes;
      nome = compressed.filename;
    }
    await ref.read(problemasRepositoryProvider).criar(
          contratoId: contrato.id,
          titulo: titulo.text.trim(),
          descricao: descricao.text.trim(),
          prioridade: prioridade,
          foto: foto,
          fotoFilename: nome,
        );
    ref.invalidate(ocorrenciasProvider);
  } on AppException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
  titulo.dispose();
  descricao.dispose();
}
