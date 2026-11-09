import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../app/router/route_access.dart';
import '../../../../core/widgets/connectivity_banner.dart';
import '../../../auth/domain/user.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final wide = MediaQuery.sizeOf(context).width >= 960;
    final location = GoRouterState.of(context).uri.path;
    final destinations = _destinationsFor(user?.role, compact: !wide);
    var selected = 0;
    for (var i = 0; i < destinations.length; i++) {
      final path = destinations[i].path;
      if (location == path || location.startsWith('$path/')) {
        selected = i;
        break;
      }
    }

    final body = Column(
      children: [
        const ConnectivityBanner(),
        Expanded(child: child),
      ],
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selected,
              onDestinationSelected: (i) => context.go(destinations[i].path),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => context.go(destinations[i].path),
        destinations: [
          for (final d in destinations)
            NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }

  List<_NavDest> _destinationsFor(UserRole? role, {required bool compact}) {
    switch (role) {
      case UserRole.vistoriador:
        return const [
          _NavDest('/agenda', 'Agenda', Icons.calendar_month_outlined),
          _NavDest('/perfil', 'Perfil', Icons.person_outline),
        ];
      case UserRole.locatario:
        return const [
          _NavDest('/locatario', 'Vistorias', Icons.home_work_outlined),
          _NavDest('/ocorrencias', 'Ocorrências', Icons.report_problem_outlined),
          _NavDest('/perfil', 'Perfil', Icons.person_outline),
        ];
      case UserRole.admin:
        if (compact) {
          return const [
            _NavDest('/admin', 'Painel', Icons.dashboard_outlined),
            _NavDest('/imoveis', 'Imóveis', Icons.apartment_outlined),
            _NavDest('/contratos', 'Contratos', Icons.description_outlined),
            _NavDest('/menu', 'Mais', Icons.menu),
          ];
        }
        return const [
          _NavDest('/admin', 'Painel', Icons.dashboard_outlined),
          _NavDest('/imoveis', 'Imóveis', Icons.apartment_outlined),
          _NavDest('/contratos', 'Contratos', Icons.description_outlined),
          _NavDest('/agenda', 'Agenda', Icons.calendar_month_outlined),
          _NavDest('/ocorrencias', 'Ocorrências', Icons.report_problem_outlined),
          _NavDest('/usuarios', 'Usuários', Icons.group_outlined),
          _NavDest('/auditoria', 'Auditoria', Icons.fact_check_outlined),
          _NavDest('/perfil', 'Perfil', Icons.person_outline),
        ];
      case UserRole.gestor:
        if (compact) {
          return const [
            _NavDest('/admin', 'Painel', Icons.dashboard_outlined),
            _NavDest('/imoveis', 'Imóveis', Icons.apartment_outlined),
            _NavDest('/contratos', 'Contratos', Icons.description_outlined),
            _NavDest('/menu', 'Mais', Icons.menu),
          ];
        }
        return const [
          _NavDest('/admin', 'Painel', Icons.dashboard_outlined),
          _NavDest('/imoveis', 'Imóveis', Icons.apartment_outlined),
          _NavDest('/contratos', 'Contratos', Icons.description_outlined),
          _NavDest('/agenda', 'Agenda', Icons.calendar_month_outlined),
          _NavDest('/ocorrencias', 'Ocorrências', Icons.report_problem_outlined),
          _NavDest('/perfil', 'Perfil', Icons.person_outline),
        ];
      default:
        return const [
          _NavDest('/perfil', 'Perfil', Icons.person_outline),
        ];
    }
  }
}

class _NavDest {
  const _NavDest(this.path, this.label, this.icon);
  final String path;
  final String label;
  final IconData icon;
}

class RoleHomeRedirect extends ConsumerWidget {
  const RoleHomeRedirect({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.go(homeForRole(user?.role));
    });
    return const Scaffold(body: OcLoadingPlaceholder());
  }
}

class OcLoadingPlaceholder extends StatelessWidget {
  const OcLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

