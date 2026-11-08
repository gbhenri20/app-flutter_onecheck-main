import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/app_widgets.dart';

class MfaPage extends ConsumerStatefulWidget {
  const MfaPage({super.key});

  @override
  ConsumerState<MfaPage> createState() => _MfaPageState();
}

class _MfaPageState extends ConsumerState<MfaPage> {
  final _codigo = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codigo.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Informe o código de 6 dígitos');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result =
          await ref.read(authStateProvider.notifier).verifyMfa(code);
      if (!mounted) return;
      if (result == null) {
        context.go('/');
      } else {
        setState(() => _error = result);
      }
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Código MFA inválido ou expirado');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _voltar() {
    ref.read(authStateProvider.notifier).abandonMfaChallenge();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(authStateProvider).pendingMfaToken;
    if (pending == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(authStateProvider).pendingMfaToken == null) {
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
      child: Column(
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
            'Código do autenticador',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.brandMuted,
                ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _codigo,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  letterSpacing: 8,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Código MFA',
              counterText: '',
              prefixIcon: Icon(Icons.pin_outlined),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            OcErrorBanner(message: _error!),
          ],
          const SizedBox(height: 22),
          OcPrimaryButton(
            label: 'Validar',
            loading: _loading,
            icon: Icons.arrow_forward,
            iconAtEnd: true,
            onPressed: _submit,
          ),
        ],
      ),
    ),
    );
  }
}
