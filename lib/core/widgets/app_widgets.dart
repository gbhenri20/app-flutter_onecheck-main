import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../utils/formatters.dart';

class OcLoading extends StatelessWidget {
  const OcLoading({super.key, this.message = 'Carregando...'});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class OcEmptyState extends StatelessWidget {
  const OcEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class OcErrorView extends StatelessWidget {
  const OcErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return OcEmptyState(
      title: 'Não foi possível carregar',
      subtitle: message,
      icon: Icons.error_outline,
      action: onRetry == null
          ? null
          : FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
    );
  }
}

class OneCheckWordmark extends StatelessWidget {
  const OneCheckWordmark({super.key, this.fontSize = 40});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      height: 1.1,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'One', style: style.copyWith(color: Colors.white)),
          TextSpan(
            text: 'Check',
            style: style.copyWith(color: AppTheme.brandGreen),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class AuthCanvas extends StatelessWidget {
  const AuthCanvas({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class OcErrorBanner extends StatelessWidget {
  const OcErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.brandDanger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.brandDanger.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.brandDanger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class OcPrimaryButton extends StatelessWidget {
  const OcPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.iconAtEnd = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool iconAtEnd;

  @override
  Widget build(BuildContext context) {
    final glyph = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Icon(icon ?? Icons.arrow_forward, size: 18);
    final text = Text(label);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: iconAtEnd
              ? [text, const SizedBox(width: 8), glyph]
              : [glyph, const SizedBox(width: 8), text],
        ),
      ),
    );
  }
}

class OcTextField extends StatelessWidget {
  const OcTextField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.textInputAction,
    this.hintText,
  });

  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final TextInputAction? textInputAction;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      enabled: enabled,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (status) {
      case 'aceito':
        bg = const Color(0xFF1B5E20);
        fg = const Color(0xFFA5D6A7);
      case 'pendente_aceite':
        bg = const Color(0xFFE65100);
        fg = const Color(0xFFFFCC80);
      case 'em_preenchimento':
        bg = const Color(0xFF01579B);
        fg = const Color(0xFF81D4FA);
      case 'rejeitado':
        bg = const Color(0xFFB71C1C);
        fg = const Color(0xFFEF9A9A);
      default:
        bg = Theme.of(context).colorScheme.surfaceContainerHighest;
        fg = Theme.of(context).colorScheme.onSurface;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bg),
      ),
      child: Text(
        labelChecklistStatus(status),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class OcInfoCard extends StatelessWidget {
  const OcInfoCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.leading,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.brandCard,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: const BorderSide(color: AppTheme.brandBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: Theme.of(context).textTheme.titleMedium),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

class OcActionTile extends StatelessWidget {
  const OcActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OcInfoCard(
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.brandMuted),
      trailing: Icon(
        Icons.chevron_right,
        color: onTap == null ? AppTheme.brandBorder : AppTheme.brandMuted,
      ),
    );
  }
}
