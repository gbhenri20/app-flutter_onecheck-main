import '../../features/auth/domain/user.dart';

/// Histórico de logs (API e registro local) é exclusivo do administrador.
bool isLogRoute(String location) {
  return location == '/historico' ||
      location == '/auditoria' ||
      location.startsWith('/auditoria/');
}

String homeForRole(UserRole? role) {
  switch (role) {
    case UserRole.vistoriador:
      return '/agenda';
    case UserRole.locatario:
      return '/locatario';
    case UserRole.admin:
    case UserRole.gestor:
      return '/admin';
    default:
      return '/perfil';
  }
}

/// Decide o redirect de sessão. O token MFA pendente prende o usuário na etapa
/// atual; ao voltar, a tela precisa limpar esse token antes de ir ao login.
String? redirectForSession({
  required bool bootstrapping,
  required bool authenticated,
  required String location,
  String? pendingMfaToken,
  String? pendingSetupToken,
  UserRole? role,
}) {
  if (bootstrapping) return null;
  final loggingIn =
      location == '/login' || location == '/mfa' || location == '/mfa-setup';
  if (!authenticated) {
    if (pendingMfaToken != null && location != '/mfa') return '/mfa';
    if (pendingSetupToken != null && location != '/mfa-setup') {
      return '/mfa-setup';
    }
    if (!loggingIn && pendingMfaToken == null && pendingSetupToken == null) {
      return '/login';
    }
    return null;
  }
  if (loggingIn) return homeForRole(role);
  if (!routeAllowed(role, location)) return homeForRole(role);
  return null;
}

bool routeAllowed(UserRole? role, String location) {
  if (isLogRoute(location)) return role == UserRole.admin;
  if (location == '/' || location == '/perfil') return true;
  if (location == '/menu') {
    return role == UserRole.admin || role == UserRole.gestor;
  }
  switch (role) {
    case UserRole.admin:
    case UserRole.gestor:
      return true;
    case UserRole.vistoriador:
      return location.startsWith('/agenda') || location.startsWith('/vistoria');
    case UserRole.locatario:
      return location.startsWith('/locatario') ||
          location.startsWith('/ocorrencias');
    default:
      return location == '/perfil';
  }
}
