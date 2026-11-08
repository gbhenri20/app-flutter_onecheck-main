import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/domain/user.dart';

class PerfilPage extends ConsumerWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final pending = ref.watch(pendingOpsCountProvider);
    final isAdmin = user?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OcInfoCard(
            title: user?.nome ?? 'Usuário',
            subtitle: '${user?.email ?? ''}\n${labelRole(user?.roleRaw ?? '')}',
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              child: Text(
                (user?.nome.isNotEmpty == true ? user!.nome[0] : '?').toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OcActionTile(
            icon: Icons.badge_outlined,
            title: 'Atualizar nome',
            onTap: () => _nome(context, ref, user?.nome ?? ''),
          ),
          const SizedBox(height: 10),
          OcActionTile(
            icon: Icons.password_outlined,
            title: 'Alterar senha',
            onTap: () => _senha(context, ref),
          ),
          const SizedBox(height: 10),
          OcActionTile(
            icon: Icons.sync,
            title: 'Fila de sincronização',
            subtitle: pending == 0
                ? 'Nenhuma operação pendente'
                : '$pending pendente(s). Elas só saem da fila depois da confirmação da API.',
            onTap: pending == 0
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final result = await ref.read(syncServiceProvider).flush();
                    ref.read(syncRevisionProvider.notifier).state++;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          result.synced > 0
                              ? '${result.synced} sincronizada(s).'
                              : 'A API ainda não confirmou o envio.',
                        ),
                      ),
                    );
                  },
          ),
          if (isAdmin) ...[
            const SizedBox(height: 10),
            OcActionTile(
              icon: Icons.history,
              title: 'Histórico local de operações',
              onTap: () => context.push('/historico'),
            ),
          ],
          const SizedBox(height: 24),
          OcPrimaryButton(
            label: 'Sair',
            icon: Icons.logout,
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _nome(BuildContext context, WidgetRef ref, String atual) async {
    final controller = TextEditingController(text: atual);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nome'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      try {
        await ref.read(authStateProvider.notifier).atualizarNome(controller.text.trim());
      } on AppException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }
    controller.dispose();
  }

  Future<void> _senha(BuildContext context, WidgetRef ref) async {
    final atual = TextEditingController();
    final nova = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterar senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: atual,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha atual'),
            ),
            TextField(
              controller: nova,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nova senha (mín. 6)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(authStateProvider.notifier).alterarSenha(
              senhaAtual: atual.text,
              novaSenha: nova.text,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Senha alterada.')),
          );
        }
      } on AppException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }
    atual.dispose();
    nova.dispose();
  }
}
