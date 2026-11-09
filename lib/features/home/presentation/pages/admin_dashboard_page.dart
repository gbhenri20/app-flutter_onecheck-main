import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/domain/user.dart';

final dashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ref.watch(auditoriaRepositoryProvider).dashboard();
  return res;
});

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardProvider);
    final isAdmin = ref.watch(authStateProvider).user?.role == UserRole.admin;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel One Check'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(dashboardProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: async.when(
        loading: () => const OcLoading(),
        error: (e, _) => OcErrorView(
          message: e is AppException ? e.message : 'Erro ao carregar painel',
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (data) {
          final cards = <MapEntry<String, String>>[
            MapEntry('Imóveis locados', '${data['imoveis_locados'] ?? data['imoveisLocados'] ?? '—'}'),
            MapEntry('Checklists pendentes', '${data['checklists_pendentes'] ?? data['checklistsPendentes'] ?? '—'}'),
            MapEntry('Problemas abertos', '${data['problemas_abertos'] ?? data['problemasAbertos'] ?? '—'}'),
            MapEntry('Vistorias agendadas', '${data['vistorias_agendadas'] ?? data['agendamentos'] ?? '—'}'),
          ];
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardProvider);
              await ref.read(dashboardProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    for (final c in cards)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(c.key, style: Theme.of(context).textTheme.bodyMedium),
                            Text(
                              c.value,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Atalhos', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Imóveis'),
                      onPressed: () => context.go('/imoveis'),
                    ),
                    ActionChip(
                      label: const Text('Contratos'),
                      onPressed: () => context.go('/contratos'),
                    ),
                    if (isAdmin)
                      ActionChip(
                        label: const Text('Usuários'),
                        onPressed: () => context.go('/usuarios'),
                      ),
                    if (isAdmin)
                      ActionChip(
                        label: const Text('Auditoria'),
                        onPressed: () => context.go('/auditoria'),
                      ),
                    ActionChip(
                      label: const Text('Ocorrências'),
                      onPressed: () => context.go('/ocorrencias'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
