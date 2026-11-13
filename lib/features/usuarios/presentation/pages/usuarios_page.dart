import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/paged.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/domain/user.dart';

final usuariosProvider =
    FutureProvider.autoDispose.family<PageResult<User>, String?>((ref, role) {
  return ref.watch(usuariosRepositoryProvider).listar(porPagina: 50, role: role);
});

const _papeis = <(String, String)>[
  ('admin', 'Administrador'),
  ('gestor', 'Gestor'),
  ('vistoriador', 'Vistoriador'),
  ('locatario', 'Locatário'),
];

class UsuariosPage extends ConsumerStatefulWidget {
  const UsuariosPage({super.key});

  @override
  ConsumerState<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends ConsumerState<UsuariosPage> {
  String? _role;

  @override
  Widget build(BuildContext context) {
    final atual = ref.watch(authStateProvider).user;
    final isAdmin = atual?.isAdmin == true;
    if (!isAdmin) {
      return const Scaffold(
        body: OcEmptyState(
          title: 'Acesso restrito',
          subtitle: 'Somente o administrador gerencia contas.',
          icon: Icons.lock_outline,
        ),
      );
    }
    final async = ref.watch(usuariosProvider(_role));
    return Scaffold(
      appBar: AppBar(title: const Text('Usuários')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _criar,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Cadastrar'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Todos'),
                    selected: _role == null,
                    onSelected: (_) => setState(() => _role = null),
                  ),
                ),
                for (final papel in _papeis)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(papel.$2),
                      selected: _role == papel.$1,
                      onSelected: (_) => setState(() => _role = papel.$1),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const OcLoading(),
              error: (e, _) => OcErrorView(
                message: e is AppException ? e.message : 'Sem permissão ou falha ao listar',
                onRetry: () => ref.invalidate(usuariosProvider(_role)),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const OcEmptyState(title: 'Nenhum usuário neste filtro');
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: page.items.length,
                  itemBuilder: (context, index) {
                    final user = page.items[index];
                    final proprio = user.id == atual?.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OcInfoCard(
                        onTap: () => _editar(user),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.brandBlue.withValues(alpha: 0.18),
                          child: Text(
                            _inicial(user.nome),
                            style: const TextStyle(
                              color: AppTheme.brandBlueHover,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: user.nome,
                        subtitle: user.email,
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Ações',
                          onSelected: (action) => _acao(user, action),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Editar')),
                            const PopupMenuItem(
                              value: 'mfa_on',
                              child: Text('Habilitar MFA'),
                            ),
                            const PopupMenuItem(
                              value: 'mfa_off',
                              child: Text('Desabilitar MFA'),
                            ),
                            const PopupMenuItem(
                              value: 'setup',
                              child: Text('Gerar segredo MFA'),
                            ),
                            if (!proprio)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Desativar'),
                              ),
                          ],
                        ),
                        footer: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _PapelChip(role: user.roleRaw),
                              if (user.mfaAtivo == true) const _MfaChip(),
                              if (proprio) const _VoceChip(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _criar() async {
    final dados = await showDialog<_DadosUsuario>(
      context: context,
      builder: (ctx) => const _UsuarioDialog(titulo: 'Novo usuário', senhaObrigatoria: true),
    );
    if (dados == null) return;
    try {
      await ref.read(usuariosRepositoryProvider).criar(
            nome: dados.nome,
            email: dados.email,
            senha: dados.senha,
            role: dados.role,
          );
      ref.invalidate(usuariosProvider(_role));
      _aviso('Usuário cadastrado.');
    } on AppException catch (e) {
      _aviso(e.message);
    }
  }

  Future<void> _editar(User user) async {
    final dados = await showDialog<_DadosUsuario>(
      context: context,
      builder: (ctx) => _UsuarioDialog(
        titulo: 'Editar usuário',
        nomeInicial: user.nome,
        emailInicial: user.email,
        roleInicial: user.roleRaw == 'unknown' ? 'locatario' : user.roleRaw,
      ),
    );
    if (dados == null) return;
    try {
      await ref.read(usuariosRepositoryProvider).atualizar(
            user.id,
            nome: dados.nome,
            email: dados.email,
            role: dados.role,
            senha: dados.senha,
          );
      ref.invalidate(usuariosProvider(_role));
      _aviso(dados.senha.isEmpty ? 'Dados atualizados.' : 'Dados e senha atualizados.');
    } on AppException catch (e) {
      _aviso(e.message);
    }
  }

  Future<void> _acao(User user, String action) async {
    if (action == 'edit') {
      await _editar(user);
      return;
    }
    final repo = ref.read(usuariosRepositoryProvider);
    try {
      switch (action) {
        case 'mfa_on':
          await repo.habilitarMfa(user.id);
          _aviso('MFA habilitado.');
        case 'mfa_off':
          await repo.desabilitarMfa(user.id);
          _aviso('MFA desabilitado.');
        case 'setup':
          final setup = await repo.setupMfa(user.id);
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Segredo MFA'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'A validação do código continua na API.',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    const Text('Segredo'),
                    const SizedBox(height: 4),
                    SelectableText(setup.secret.isEmpty ? '—' : setup.secret),
                    if (setup.provisioningUri.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Link de configuração'),
                      const SizedBox(height: 4),
                      SelectableText(setup.provisioningUri),
                    ],
                  ],
                ),
              ),
              actions: [
                FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
              ],
            ),
          );
        case 'delete':
          final nav = Navigator.of(context);
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Desativar usuário'),
              content: Text('${user.nome} deixa de acessar o app. A conta permanece no histórico.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Desativar')),
              ],
            ),
          );
          if (ok == true && nav.mounted) {
            await repo.excluir(user.id);
            _aviso('Usuário desativado.');
          } else {
            return;
          }
      }
      ref.invalidate(usuariosProvider(_role));
    } on AppException catch (e) {
      _aviso(e.message);
    }
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }
}

class _DadosUsuario {
  const _DadosUsuario({
    required this.nome,
    required this.email,
    required this.role,
    required this.senha,
  });

  final String nome;
  final String email;
  final String role;
  final String senha;
}

class _UsuarioDialog extends StatefulWidget {
  const _UsuarioDialog({
    required this.titulo,
    this.nomeInicial = '',
    this.emailInicial = '',
    this.roleInicial = 'locatario',
    this.senhaObrigatoria = false,
  });

  final String titulo;
  final String nomeInicial;
  final String emailInicial;
  final String roleInicial;
  final bool senhaObrigatoria;

  @override
  State<_UsuarioDialog> createState() => _UsuarioDialogState();
}

class _UsuarioDialogState extends State<_UsuarioDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _email;
  late final TextEditingController _senha;
  late final TextEditingController _confirma;
  late String _role;
  var _oculta = true;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.nomeInicial);
    _email = TextEditingController(text: widget.emailInicial);
    _senha = TextEditingController();
    _confirma = TextEditingController();
    _role = widget.roleInicial;
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _confirma.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OcTextField(
                  controller: _nome,
                  label: 'Nome',
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 10),
                OcTextField(
                  controller: _email,
                  label: 'E-mail',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final texto = v?.trim() ?? '';
                    if (!texto.contains('@') || !texto.contains('.')) {
                      return 'Informe um e-mail válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey('papel-$_role'),
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Papel'),
                  items: [
                    for (final papel in _papeis)
                      DropdownMenuItem(value: papel.$1, child: Text(papel.$2)),
                  ],
                  onChanged: (value) => setState(() => _role = value ?? _role),
                ),
                const SizedBox(height: 10),
                OcTextField(
                  controller: _senha,
                  label: widget.senhaObrigatoria ? 'Senha' : 'Nova senha',
                  hintText: widget.senhaObrigatoria ? 'Mínimo de 6 caracteres' : 'Em branco mantém a atual',
                  obscureText: _oculta,
                  textInputAction: TextInputAction.next,
                  suffixIcon: IconButton(
                    tooltip: _oculta ? 'Mostrar senha' : 'Ocultar senha',
                    onPressed: () => setState(() => _oculta = !_oculta),
                    icon: Icon(_oculta ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                  validator: (v) {
                    final texto = v ?? '';
                    if (texto.isEmpty) {
                      return widget.senhaObrigatoria ? 'Informe a senha' : null;
                    }
                    if (texto.length < 6) return 'Mínimo de 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                OcTextField(
                  controller: _confirma,
                  label: 'Confirmar senha',
                  obscureText: _oculta,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (_senha.text.isEmpty && (v ?? '').isEmpty) return null;
                    if (v != _senha.text) return 'As senhas não coincidem';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            Navigator.pop(
              context,
              _DadosUsuario(
                nome: _nome.text.trim(),
                email: _email.text.trim(),
                role: _role,
                senha: _senha.text,
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _PapelChip extends StatelessWidget {
  const _PapelChip({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final cor = switch (role) {
      'admin' => AppTheme.brandDanger,
      'gestor' => AppTheme.brandBlueHover,
      'vistoriador' => AppTheme.brandGreen,
      _ => AppTheme.brandMuted,
    };
    return _Etiqueta(texto: labelRole(role), cor: cor);
  }
}

class _MfaChip extends StatelessWidget {
  const _MfaChip();

  @override
  Widget build(BuildContext context) {
    return const _Etiqueta(texto: 'MFA ativo', cor: AppTheme.brandGreen);
  }
}

class _VoceChip extends StatelessWidget {
  const _VoceChip();

  @override
  Widget build(BuildContext context) {
    return const _Etiqueta(texto: 'Você', cor: AppTheme.brandBlueHover);
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.7)),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

String _inicial(String nome) {
  final texto = nome.trim();
  if (texto.isEmpty) return '?';
  return texto[0].toUpperCase();
}
