import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_check/app/providers.dart';
import 'package:one_check/app/theme/app_theme.dart';
import 'package:one_check/core/config/app_config.dart';
import 'package:one_check/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('tela de login exibe marca e valida campos', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.forTests()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const LoginPage(),
        ),
      ),
    );

    expect(find.text('OneCheck'), findsOneWidget);
    expect(find.text('Sistema de gestão de imóveis'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(
      find.text('Contas com MFA: após a senha, informe o código do autenticador.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe o e-mail'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);
  });
}
