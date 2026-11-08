import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sync/sync_service.dart';
import 'providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

class OneCheckApp extends ConsumerWidget {
  const OneCheckApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    ref.listen(sessionExpiredProvider, (prev, next) {
      if (prev != null && next > prev) {
        rootMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Sessão expirada. Entre novamente.')),
        );
      }
    });
    ref.listen(onlineProvider, (prev, next) async {
      if (next.valueOrNull != true) return;
      if (prev?.valueOrNull == true) return;
      final result = await ref.read(syncServiceProvider).flush();
      ref.read(syncRevisionProvider.notifier).state++;
      if (result.synced == 0 && result.failed == 0) return;
      rootMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(_syncMessage(result))),
      );
    });

    return MaterialApp.router(
      title: 'OneCheck',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootMessengerKey,
      theme: AppTheme.dark,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}

String _syncMessage(SyncFlushResult result) {
  if (result.synced > 0 && result.failed == 0) {
    return '${result.synced} operação(ões) sincronizada(s) com a API.';
  }
  if (result.synced > 0) {
    return '${result.synced} sincronizada(s). ${result.failed} ainda pendente(s).';
  }
  return 'Ainda há operações pendentes. A API não confirmou o envio.';
}
