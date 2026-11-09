import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/domain/user.dart';

class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authStateProvider).user?.role;
    final items = <(String, String, IconData)>[
      ('/agenda', 'Agenda de vistorias', Icons.calendar_month_outlined),
      ('/ocorrencias', 'Ocorrências', Icons.report_problem_outlined),
      if (role == UserRole.admin)
        ('/usuarios', 'Usuários', Icons.group_outlined),
      if (role == UserRole.admin)
        ('/auditoria', 'Auditoria', Icons.fact_check_outlined),
      if (role == UserRole.admin)
        ('/historico', 'Histórico local', Icons.history),
      ('/perfil', 'Perfil', Icons.person_outline),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            OcActionTile(
              icon: items[i].$3,
              title: items[i].$2,
              onTap: () => context.go(items[i].$1),
            ),
          ],
        ],
      ),
    );
  }
}
