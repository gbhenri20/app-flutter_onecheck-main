import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/agenda/presentation/pages/agenda_page.dart';
import '../../features/auditoria/presentation/pages/auditoria_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/mfa_page.dart';
import '../../features/auth/presentation/pages/mfa_setup_page.dart';
import '../../features/checklist/presentation/pages/revisao_page.dart';
import '../../features/checklist/presentation/pages/vistoria_checklist_page.dart';
import '../../features/contratos/presentation/pages/contrato_detalhe_page.dart';
import '../../features/contratos/presentation/pages/contratos_page.dart';
import '../../features/home/presentation/pages/admin_dashboard_page.dart';
import '../../features/home/presentation/pages/home_shell.dart';
import '../../features/home/presentation/pages/menu_page.dart';
import '../../features/imoveis/presentation/pages/imovel_detalhe_page.dart';
import '../../features/imoveis/presentation/pages/imoveis_page.dart';
import '../../features/logs/presentation/historico_page.dart';
import '../../features/ocorrencias/presentation/pages/ocorrencia_detalhe_page.dart';
import '../../features/ocorrencias/presentation/pages/ocorrencias_page.dart';
import '../../features/perfil/presentation/pages/perfil_page.dart';
import '../../features/usuarios/presentation/pages/usuarios_page.dart';
import '../../features/vistoria/presentation/pages/locatario_vistorias_page.dart';
import '../providers.dart';
import 'route_access.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen<AuthState>(authStateProvider, (_, __) {
    refresh.value++;
  });

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      return redirectForSession(
        bootstrapping: auth.status == AuthStatus.unknown,
        authenticated: auth.status == AuthStatus.authenticated,
        location: state.matchedLocation,
        pendingMfaToken: auth.pendingMfaToken,
        pendingSetupToken: auth.pendingSetupToken,
        role: auth.user?.role,
      );
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/mfa', builder: (_, __) => const MfaPage()),
      GoRoute(path: '/mfa-setup', builder: (_, __) => const MfaSetupPage()),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const RoleHomeRedirect()),
          GoRoute(path: '/agenda', builder: (_, __) => const AgendaPage()),
          GoRoute(
            path: '/vistoria/:id',
            builder: (_, state) => VistoriaChecklistPage(
              checklistId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/vistoria/:id/revisao',
            builder: (_, state) => RevisaoPage(
              checklistId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/locatario',
            builder: (_, __) => const LocatarioVistoriasPage(),
          ),
          GoRoute(
            path: '/locatario/vistoria/:id',
            builder: (_, state) => LocatarioDetalhePage(
              checklistId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/ocorrencias',
            builder: (_, __) => const OcorrenciasPage(),
          ),
          GoRoute(
            path: '/ocorrencias/:id',
            builder: (_, state) => OcorrenciaDetalhePage(
              problemaId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardPage()),
          GoRoute(path: '/imoveis', builder: (_, __) => const ImoveisPage()),
          GoRoute(
            path: '/imoveis/:id',
            builder: (_, state) => ImovelDetalhePage(
              imovelId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(path: '/contratos', builder: (_, __) => const ContratosPage()),
          GoRoute(
            path: '/contratos/:id',
            builder: (_, state) => ContratoDetalhePage(
              contratoId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(path: '/usuarios', builder: (_, __) => const UsuariosPage()),
          GoRoute(path: '/auditoria', builder: (_, __) => const AuditoriaPage()),
          GoRoute(path: '/menu', builder: (_, __) => const MenuPage()),
          GoRoute(path: '/historico', builder: (_, __) => const HistoricoPage()),
          GoRoute(path: '/perfil', builder: (_, __) => const PerfilPage()),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
