import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final String? trend;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.brand600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface800 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.withValues(alpha: 0.14)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: c.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
            children: [
              // Soft color washes in the corners for a bit of life
              Positioned(
                right: -18, top: -18,
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: 0.07)),
                ),
              ),
              Positioned(
                left: -16, bottom: -22,
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: 0.05)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [c, Color.lerp(c, Colors.black, 0.22)!],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: Icon(icon, color: Colors.white, size: 18),
                        ),
                        if (trend != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              trend!,
                              style: const TextStyle(
                                color: AppColors.success600,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      value,
                      style: GoogleFonts.domine(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.surface900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.surface400 : AppColors.surface500,
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 16,
                          color: isDark ? AppColors.surface600 : AppColors.surface300),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
