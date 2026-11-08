import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineProvider);
    final pending = ref.watch(pendingOpsCountProvider);
    final offline = online.valueOrNull == false;
    if (!offline && pending == 0) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: offline ? scheme.errorContainer : scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(offline ? Icons.wifi_off : Icons.sync, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                offline
                    ? 'Sem conexão. Nada é concluído no servidor até a API responder.'
                    : '$pending operação(ões) pendente(s) de sincronização.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (!offline && pending > 0)
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final result = await ref.read(syncServiceProvider).flush();
                  ref.read(syncRevisionProvider.notifier).state++;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        result.synced > 0
                            ? '${result.synced} sincronizada(s).'
                            : 'A API ainda não confirmou as operações pendentes.',
                      ),
                    ),
                  );
                },
                child: const Text('Sincronizar'),
              ),
          ],
        ),
      ),
    );
  }
}
