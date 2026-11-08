import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/auth_session.dart';

class MfaSetupPage extends ConsumerStatefulWidget {
  const MfaSetupPage({super.key});

  @override
  ConsumerState<MfaSetupPage> createState() => _MfaSetupPageState();
}

class _MfaSetupPageState extends ConsumerState<MfaSetupPage> {
  final _codigo = TextEditingController();
  MfaSetupData? _setup;
  bool _loadingSetup = true;
  bool _activating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(authStateProvider.notifier).loadSetupData();
      if (mounted) {
        setState(() {
          _setup = data;
          _loadingSetup = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingSetup = false;
          _error = 'Não foi possível iniciar o setup do MFA';
        });
      }
    }
  }

  Future<void> _activate() async {
    final code = _codigo.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Informe o código de 6 dígitos');
      return;
    }
    setState(() {
      _activating = true;
      _error = null;
    });
    try {
      final result =
          await ref.read(authStateProvider.notifier).activateSetup(code);
      if (!mounted) return;
      if (result == null) {
        context.go('/');
      } else {
        setState(() => _error = result);
      }
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Não foi possível ativar o MFA');
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  void _voltar() {
    ref.read(authStateProvider.notifier).abandonMfaChallenge();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(authStateProvider).pendingSetupToken == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(authStateProvider).pendingSetupToken == null) {
          context.go('/login');
        }
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _voltar();
      },
      child: AuthCanvas(
      child: _loadingSetup
          ? const OcLoading(message: 'Gerando segredo MFA...')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _voltar,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Voltar'),
                  ),
                ),
                const OneCheckWordmark(fontSize: 32),
                const SizedBox(height: 8),
                Text(
                  'Primeiro acesso — ative o autenticador',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.brandMuted,
                      ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Escaneie o QR Code ou digite o segredo no aplicativo autenticador, '
                  'depois confirme com o código gerado.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_setup?.qrUrl.isNotEmpty == true)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _setup!.qrUrl,
                        width: 200,
                        height: 200,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.qr_code_2,
                          size: 120,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SelectableText(
                  'Segredo: ${_setup?.secret ?? '—'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _codigo,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Código de confirmação',
                    counterText: '',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  OcErrorBanner(message: _error!),
                ],
                const SizedBox(height: 22),
                OcPrimaryButton(
                  label: 'Ativar e entrar',
                  loading: _activating,
                  icon: Icons.arrow_forward,
                  iconAtEnd: true,
                  onPressed: _activate,
                ),
              ],
            ),
    ),
    );
  }
}
