import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../auth/domain/user.dart';
import '../../../checklist/domain/checklist_models.dart';
import 'agenda_filtro.dart';

final agendaFiltroProvider = StateProvider<AgendaFiltro>(
  (ref) => const AgendaFiltro(),
);

final nomesVistoriadorProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final role = ref.watch(authStateProvider).user?.role;
  if (role != UserRole.admin && role != UserRole.gestor) return {};
  final page = await ref.watch(usuariosRepositoryProvider).listarOperacionais(
        role: 'vistoriador',
      );
  return {for (final user in page.items) user.id: user.nome};
});

final agendaProvider = FutureProvider.autoDispose<List<AgendaItem>>((ref) async {
  return ref.watch(agendaRepositoryProvider).carregarAgenda();
});
