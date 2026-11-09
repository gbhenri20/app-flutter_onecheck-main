import 'package:flutter_test/flutter_test.dart';
import 'package:one_check/app/router/route_access.dart';
import 'package:one_check/features/auth/domain/user.dart';

void main() {
  test('somente o administrador abre o histórico de logs', () {
    for (final role in UserRole.values) {
      final allowed = routeAllowed(role, '/auditoria');
      expect(allowed, role == UserRole.admin, reason: role.name);
      expect(routeAllowed(role, '/historico'), role == UserRole.admin);
    }
  });

  test('usuário comum não entra no menu administrativo', () {
    expect(routeAllowed(UserRole.locatario, '/menu'), isFalse);
    expect(routeAllowed(UserRole.vistoriador, '/usuarios'), isFalse);
    expect(routeAllowed(UserRole.gestor, '/usuarios'), isFalse);
    expect(routeAllowed(UserRole.locatario, '/usuarios'), isFalse);
    expect(routeAllowed(UserRole.admin, '/usuarios'), isTrue);
    expect(routeAllowed(UserRole.gestor, '/imoveis'), isTrue);
    expect(routeAllowed(UserRole.gestor, '/agenda'), isTrue);
    expect(routeAllowed(UserRole.gestor, '/contratos'), isTrue);
    expect(routeAllowed(UserRole.gestor, '/auditoria'), isFalse);
    expect(routeAllowed(UserRole.locatario, '/ocorrencias'), isTrue);
    expect(homeForRole(UserRole.admin), '/admin');
    expect(homeForRole(UserRole.locatario), '/locatario');
  });
}
