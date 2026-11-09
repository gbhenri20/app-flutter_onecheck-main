import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/paged.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/domain/user.dart';

final usuariosProvider =
    FutureProvider.autoDispose.family<PageResult<User>, String?>((ref, role) {
  return ref.watch(usuariosRepositoryProvider).listar(porPagina: 50, role: role);
});

class UsuariosPage extends ConsumerStatefulWidget {
  const UsuariosPage({super.key});

  @override
  ConsumerState<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends ConsumerState<UsuariosPage> {
  String? _role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authStateProvider).user?.isAdmin == true;
    if (!isAdmin) {
      return const Scaffold(
        body: OcEmptyState(
          title: 'Acesso restrito',
          subtitle: 'Somente o administrador gerencia contas.',
          icon: Icons.lock_outline,
        ),
      );
    }
    final async = ref.watch(usuariosProvider(_role));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuários'),
        actions: [
          PopupMenuButton<String?>(
            onSelected: (value) => setState(() => _role = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: null, child: Text('Todos')),
              PopupMenuItem(value: 'admin', child: Text('Admin')),
              PopupMenuItem(value: 'gestor', child: Text('Gestor')),
              PopupMenuItem(value: 'vistoriador', child: Text('Vistoriador')),
              PopupMenuItem(value: 'locatario', child: Text('Locatário')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _criar,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Cadastrar'),
      ),
      body: async.when(
        loading: () => const OcLoading(),
        error: (e, _) => OcErrorView(
          message: e is AppException ? e.message : 'Sem permissão ou falha ao listar',
          onRetry: () => ref.invalidate(usuariosProvider(_role)),
        ),
        data: (page) {
          if (page.items.isEmpty) {
            return const OcEmptyState(title: 'Nenhum usuário neste filtro');
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: page.items.length,
            itemBuilder: (context, index) {
              final user = page.items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OcInfoCard(
                  title: user.nome,
                  subtitle:
                      '${user.email}\n${labelRole(user.roleRaw)}'
                      '${user.mfaAtivo == true ? ' · MFA ativo' : ''}',
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) => _acao(user, action),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'mfa_on', child: Text('Habilitar MFA')),
                      PopupMenuItem(value: 'mfa_off', child: Text('Desabilitar MFA')),
                      PopupMenuItem(value: 'setup', child: Text('Gerar segredo MFA')),
                      PopupMenuItem(value: 'delete', child: Text('Desativar')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _criar() async {
    final nome = TextEditingController();
    final email = TextEditingController();
    final senha = TextEditingController();
    var role = 'locatario';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Novo usuário'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome')),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'E-mail')),
              TextField(
                controller: senha,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha (mín. 6)'),
              ),
              DropdownButtonFormField<String>(
                key: ValueKey(role),
                initialValue: role,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'gestor', child: Text('Gestor')),
                  DropdownMenuItem(value: 'vistoriador', child: Text('Vistoriador')),
                  DropdownMenuItem(value: 'locatario', child: Text('Locatário')),
                ],
                onChanged: (value) => setLocal(() => role = value ?? 'locatario'),
              ),
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
        await ref.read(usuariosRepositoryProvider).criar(
              nome: nome.text.trim(),
              email: email.text.trim(),
              senha: senha.text,
              role: role,
            );
        ref.invalidate(usuariosProvider(_role));
      } on AppException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }
    nome.dispose();
    email.dispose();
    senha.dispose();
  }

  Future<void> _acao(User user, String action) async {
    final repo = ref.read(usuariosRepositoryProvider);
    try {
      switch (action) {
        case 'edit':
          final nome = TextEditingController(text: user.nome);
          final email = TextEditingController(text: user.email);
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Editar usuário'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome')),
                  TextField(controller: email, decoration: const InputDecoration(labelText: 'E-mail')),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
              ],
            ),
          );
          if (ok == true) {
            await repo.atualizar(user.id, nome: nome.text.trim(), email: email.text.trim());
          }
          nome.dispose();
          email.dispose();
        case 'mfa_on':
          await repo.habilitarMfa(user.id);
        case 'mfa_off':
          await repo.desabilitarMfa(user.id);
        case 'setup':
          final setup = await repo.setupMfa(user.id);
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Segredo MFA'),
              content: SelectableText(
                'A validação continua na API. Segredo:\n${setup.secret}\n\n${setup.provisioningUri}',
              ),
              actions: [
                FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
              ],
            ),
          );
        case 'delete':
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Desativar usuário'),
              content: Text('Desativar ${user.nome}? A exclusão é lógica.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Desativar')),
              ],
            ),
          );
          if (ok == true) await repo.excluir(user.id);
      }
      ref.invalidate(usuariosProvider(_role));
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
