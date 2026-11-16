import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final bool fullWidth;
  final IconData? icon;
  final double? fontSize;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.fullWidth = true,
    this.icon,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget child = loading
        ? const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Text(label, style: TextStyle(fontSize: fontSize ?? 14, fontWeight: FontWeight.w600)),
            ],
          );

    final btn = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.secondary => ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.surface700 : AppColors.surface100,
            foregroundColor: isDark ? Colors.white : AppColors.surface800,
          ),
          child: child,
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: loading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: isDark ? AppColors.surface300 : AppColors.surface600,
          ),
          child: child,
        ),
      AppButtonVariant.danger => ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger500,
            foregroundColor: Colors.white,
          ),
          child: child,
        ),
    };

    if (fullWidth) return SizedBox(width: double.infinity, child: btn);
    return btn;
  }
}
