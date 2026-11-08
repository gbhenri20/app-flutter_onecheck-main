import 'package:flutter_test/flutter_test.dart';
import 'package:one_check/app/router/route_access.dart';
import 'package:one_check/features/auth/domain/user.dart';

void main() {
  test('token de setup prende na ativação e a volta ao login exige limpar o token', () {
    expect(
      redirectForSession(
        bootstrapping: false,
        authenticated: false,
        location: '/login',
        pendingSetupToken: 'setup',
        role: UserRole.admin,
      ),
      '/mfa-setup',
    );
    expect(
      redirectForSession(
        bootstrapping: false,
        authenticated: false,
        location: '/login',
        role: UserRole.admin,
      ),
      isNull,
    );
  });

  test('token de verificação prende no código e libera o login quando some', () {
    expect(
      redirectForSession(
        bootstrapping: false,
        authenticated: false,
        location: '/login',
        pendingMfaToken: 'mfa',
        role: UserRole.gestor,
      ),
      '/mfa',
    );
    expect(
      redirectForSession(
        bootstrapping: false,
        authenticated: false,
        location: '/mfa',
        pendingMfaToken: 'mfa',
        role: UserRole.gestor,
      ),
      isNull,
    );
  });

  test('sessão já autenticada não permanece nas telas de MFA', () {
    expect(
      redirectForSession(
        bootstrapping: false,
        authenticated: true,
        location: '/mfa-setup',
        role: UserRole.vistoriador,
      ),
      '/agenda',
    );
  });
}
