import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/domain/user.dart';
import '../../../../core/network/paged.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/log_operacao.dart';

class AuditoriaFiltro {
  const AuditoriaFiltro({
    this.pagina = 1,
    this.entidade,
    this.usuarioId,
    this.de,
    this.ate,
  });

  final int pagina;
  final String? entidade;
  final String? usuarioId;
  final String? de;
  final String? ate;

  AuditoriaFiltro copyWith({
    int? pagina,
    String? entidade,
    String? usuarioId,
    String? de,
    String? ate,
    bool clearEntidade = false,
    bool clearUsuario = false,
  }) {
    return AuditoriaFiltro(
      pagina: pagina ?? this.pagina,
      entidade: clearEntidade ? null : (entidade ?? this.entidade),
      usuarioId: clearUsuario ? null : (usuarioId ?? this.usuarioId),
      de: de ?? this.de,
      ate: ate ?? this.ate,
    );
  }
}

final auditoriaFiltroProvider =
    StateProvider<AuditoriaFiltro>((ref) => const AuditoriaFiltro());

final auditoriaProvider =
    FutureProvider.autoDispose<PageResult<LogOperacao>>((ref) {
  final filtro = ref.watch(auditoriaFiltroProvider);
  final role = ref.watch(authStateProvider).user?.role;
  return ref.watch(auditoriaRepositoryProvider).listar(
        role: role,
        pagina: filtro.pagina,
        entidade: filtro.entidade,
        usuarioId: filtro.usuarioId,
        de: filtro.de,
        ate: filtro.ate,
      );
});

class AuditoriaPage extends ConsumerWidget {
  const AuditoriaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authStateProvider).user?.role == UserRole.admin;
    if (!isAdmin) {
      return const Scaffold(
        body: OcEmptyState(
          title: 'Acesso restrito',
          subtitle: 'O histórico de logs é exclusivo do administrador.',
          icon: Icons.lock_outline,
        ),
      );
    }
    final async = ref.watch(auditoriaProvider);
    final filtro = ref.watch(auditoriaFiltroProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Auditoria')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FiltroCampo(
                  label: 'Entidade',
                  value: filtro.entidade ?? '',
                  onSubmitted: (value) {
                    ref.read(auditoriaFiltroProvider.notifier).state = filtro.copyWith(
                      pagina: 1,
                      entidade: value,
                      clearEntidade: value.isEmpty,
                    );
                  },
                ),
                _FiltroCampo(
                  label: 'Usuário (id)',
                  value: filtro.usuarioId ?? '',
                  onSubmitted: (value) {
                    ref.read(auditoriaFiltroProvider.notifier).state = filtro.copyWith(
                      pagina: 1,
                      usuarioId: value,
                      clearUsuario: value.isEmpty,
                    );
                  },
                ),
                _FiltroCampo(
                  label: 'De (AAAA-MM-DD)',
                  value: filtro.de ?? '',
                  onSubmitted: (value) {
                    ref.read(auditoriaFiltroProvider.notifier).state =
                        filtro.copyWith(pagina: 1, de: value);
                  },
                ),
                _FiltroCampo(
                  label: 'Até (AAAA-MM-DD)',
                  value: filtro.ate ?? '',
                  onSubmitted: (value) {
                    ref.read(auditoriaFiltroProvider.notifier).state =
                        filtro.copyWith(pagina: 1, ate: value);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const OcLoading(),
              error: (e, _) => OcErrorView(
                message: e is AppException ? e.message : 'Falha ao carregar logs',
                onRetry: () => ref.invalidate(auditoriaProvider),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const OcEmptyState(
                    title: 'Nenhum log',
                    subtitle: 'Ajuste os filtros ou aguarde novas operações na API.',
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: page.items.length,
                        itemBuilder: (context, index) {
                          final log = page.items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: OcInfoCard(
                              title: '${log.acao} · ${log.entidade ?? 'sistema'}',
                              subtitle:
                                  '${formatDateTime(log.createdAt)}\n'
                                  'Usuário ${log.usuarioId ?? '—'}\n'
                                  '${log.detalhes ?? ''}',
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Página ${page.pagina} · ${page.total} registros'),
                          Row(
                            children: [
                              IconButton(
                                onPressed: page.pagina <= 1
                                    ? null
                                    : () => ref.read(auditoriaFiltroProvider.notifier).state =
                                        filtro.copyWith(pagina: page.pagina - 1),
                                icon: const Icon(Icons.chevron_left),
                              ),
                              IconButton(
                                onPressed: page.hasMore
                                    ? () => ref.read(auditoriaFiltroProvider.notifier).state =
                                        filtro.copyWith(pagina: page.pagina + 1)
                                    : null,
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltroCampo extends StatefulWidget {
  const _FiltroCampo({
    required this.label,
    required this.value,
    required this.onSubmitted,
  });

  final String label;
  final String value;
  final ValueChanged<String> onSubmitted;

  @override
  State<_FiltroCampo> createState() => _FiltroCampoState();
}

class _FiltroCampoState extends State<_FiltroCampo> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _FiltroCampo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(labelText: widget.label, isDense: true),
        onSubmitted: (value) => widget.onSubmitted(value.trim()),
      ),
    );
  }
}
