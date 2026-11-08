import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/paged.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../checklist/domain/checklist_models.dart';

final imoveisProvider = FutureProvider.autoDispose
    .family<PageResult<Imovel>, String?>((ref, status) {
  return ref.watch(imoveisRepositoryProvider).listar(
        porPagina: 50,
        status: status,
        comEndereco: true,
      );
});

class ImoveisPage extends ConsumerStatefulWidget {
  const ImoveisPage({super.key});

  @override
  ConsumerState<ImoveisPage> createState() => _ImoveisPageState();
}

class _ImoveisPageState extends ConsumerState<ImoveisPage> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(imoveisProvider(_status));
    final canManage = ref.watch(authStateProvider).user?.isGestor == true;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Imóveis'),
        actions: [
          PopupMenuButton<String?>(
            initialValue: _status,
            onSelected: (value) => setState(() => _status = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: null, child: Text('Todos')),
              PopupMenuItem(value: 'disponivel', child: Text('Disponíveis')),
              PopupMenuItem(value: 'locado', child: Text('Locados')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: () => ref.invalidate(imoveisProvider(_status)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _form(context),
              icon: const Icon(Icons.add),
              label: const Text('Novo imóvel'),
            )
          : null,
      body: async.when(
        loading: () => const OcLoading(),
        error: (e, _) => OcErrorView(
          message: e is AppException ? e.message : 'Erro ao listar imóveis',
          onRetry: () => ref.invalidate(imoveisProvider(_status)),
        ),
        data: (page) {
          if (page.items.isEmpty) {
            return const OcEmptyState(
              title: 'Nenhum imóvel',
              subtitle: 'Cadastre um imóvel ou ajuste o filtro de status.',
              icon: Icons.apartment_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: page.items.length,
            itemBuilder: (context, index) {
              final imovel = page.items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OcInfoCard(
                  title: imovel.nomeExibicao,
                  subtitle:
                      '${imovel.tipo ?? '—'} · ${labelImovelStatus(imovel.status)}\n'
                      '${imovel.endereco?.linhaCompleta ?? 'Sem endereço'}',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/imoveis/${imovel.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _form(BuildContext context) async {
    final tipo = TextEditingController();
    final titulo = TextEditingController();
    final codigo = TextEditingController();
    final rua = TextEditingController();
    final numero = TextEditingController();
    final cidade = TextEditingController();
    final estado = TextEditingController();
    final cep = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo imóvel'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: tipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Informe o tipo' : null,
                  ),
                  TextFormField(
                    controller: titulo,
                    decoration: const InputDecoration(labelText: 'Título'),
                  ),
                  TextFormField(
                    controller: codigo,
                    decoration: const InputDecoration(labelText: 'Código'),
                  ),
                  TextFormField(
                    controller: rua,
                    decoration: const InputDecoration(labelText: 'Rua'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Informe a rua' : null,
                  ),
                  TextFormField(
                    controller: numero,
                    decoration: const InputDecoration(labelText: 'Número'),
                  ),
                  TextFormField(
                    controller: cidade,
                    decoration: const InputDecoration(labelText: 'Cidade'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Informe a cidade'
                        : null,
                  ),
                  TextFormField(
                    controller: estado,
                    decoration: const InputDecoration(labelText: 'UF'),
                    validator: (v) =>
                        v == null || v.trim().length < 2 ? 'Informe a UF' : null,
                  ),
                  TextFormField(
                    controller: cep,
                    decoration: const InputDecoration(labelText: 'CEP'),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      _disposeControllers([tipo, titulo, codigo, rua, numero, cidade, estado, cep]);
      return;
    }
    try {
      await ref.read(imoveisRepositoryProvider).criar({
        'tipo': tipo.text.trim(),
        if (titulo.text.trim().isNotEmpty) 'titulo': titulo.text.trim(),
        if (codigo.text.trim().isNotEmpty) 'codigo': codigo.text.trim(),
        'status': 'disponivel',
        'endereco': {
          'rua': rua.text.trim(),
          if (numero.text.trim().isNotEmpty) 'numero': numero.text.trim(),
          'cidade': cidade.text.trim(),
          'estado': estado.text.trim(),
          if (cep.text.trim().isNotEmpty) 'cep': cep.text.trim(),
        },
      });
      ref.invalidate(imoveisProvider(_status));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imóvel cadastrado.')),
        );
      }
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      _disposeControllers([tipo, titulo, codigo, rua, numero, cidade, estado, cep]);
    }
  }

  void _disposeControllers(List<TextEditingController> items) {
    for (final item in items) {
      item.dispose();
    }
  }
}
