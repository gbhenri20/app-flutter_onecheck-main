import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/problema.dart';
import 'ocorrencias_page.dart';

final problemaProvider =
    FutureProvider.autoDispose.family<Problema, String>((ref, id) {
  return ref.watch(problemasRepositoryProvider).get(id);
});

class OcorrenciaDetalhePage extends ConsumerWidget {
  const OcorrenciaDetalhePage({super.key, required this.problemaId});

  final String problemaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(problemaProvider(problemaId));
    final canManage = ref.watch(authStateProvider).user?.isGestor == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Ocorrência')),
      body: async.when(
        loading: () => const OcLoading(),
        error: (e, _) => OcErrorView(
          message: e is AppException ? e.message : 'Ocorrência indisponível',
          onRetry: () => ref.invalidate(problemaProvider(problemaId)),
        ),
        data: (problema) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OcInfoCard(
              title: problema.titulo,
              subtitle:
                  '${labelProblemaStatus(problema.status)} · ${labelPrioridade(problema.prioridade)}\n'
                  '${problema.descricao ?? ''}\n'
                  '${formatDateTime(problema.createdAt)}',
            ),
            if (canManage) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(problema.status),
                initialValue: _statusValido(problema.status),
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'aberto', child: Text('Aberto')),
                  DropdownMenuItem(value: 'em_andamento', child: Text('Em andamento')),
                  DropdownMenuItem(value: 'em_analise', child: Text('Em análise')),
                  DropdownMenuItem(value: 'resolvido', child: Text('Resolvido')),
                  DropdownMenuItem(value: 'fechado', child: Text('Fechado')),
                ],
                onChanged: (value) async {
                  if (value == null || value == problema.status) return;
                  try {
                    await ref.read(problemasRepositoryProvider).atualizarStatus(
                          problemaId: problema.id,
                          status: value,
                        );
                    ref.invalidate(problemaProvider(problemaId));
                    ref.invalidate(ocorrenciasProvider);
                  } on AppException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message)),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => _atualizacao(context, ref),
                icon: const Icon(Icons.timeline),
                label: const Text('Registrar atualização'),
              ),
            ],
            const SizedBox(height: 20),
            Text('Linha do tempo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (problema.atualizacoes.isEmpty)
              const Text('Nenhuma atualização registrada pela API.')
            else
              for (final item in problema.atualizacoes)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.descricao),
                  subtitle: Text(
                    '${formatDateTime(item.createdAt)}'
                    '${item.fotoUrl != null ? '\nFoto de reparo anexada' : ''}',
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String _statusValido(String status) {
    const allowed = {
      'aberto',
      'em_andamento',
      'em_analise',
      'resolvido',
      'fechado',
    };
    return allowed.contains(status) ? status : 'aberto';
  }

  Future<void> _atualizacao(BuildContext context, WidgetRef ref) async {
    final descricao = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Atualização'),
        content: TextField(
          controller: descricao,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Descrição (mínimo 5 caracteres)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar')),
        ],
      ),
    );
    if (ok != true) {
      descricao.dispose();
      return;
    }
    if (descricao.text.trim().length < 5) {
      descricao.dispose();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A descrição precisa de pelo menos 5 caracteres.')),
        );
      }
      return;
    }
    Uint8List? foto;
    String? nome;
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      final compressed = await const ImageCompressor().compress(
        bytes: await file.readAsBytes(),
        filename: file.name,
      );
      foto = compressed.bytes;
      nome = compressed.filename;
    }
    try {
      await ref.read(problemasRepositoryProvider).registrarAtualizacao(
            problemaId: problemaId,
            descricao: descricao.text.trim(),
            foto: foto,
            fotoFilename: nome,
          );
      ref.invalidate(problemaProvider(problemaId));
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
    descricao.dispose();
  }
}
