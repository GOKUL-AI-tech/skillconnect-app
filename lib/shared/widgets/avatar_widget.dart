import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool online;
  /// Border radius for the avatar. Defaults to circular (size/2).
  final double? radius;
  /// Optional override for the fallback-initials background. Defaults to the
  /// brand berry gradient when not set.
  final Color? color;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
    this.online = false,
    this.radius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(name);
    final avatar = ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? size),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              width: size, height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => _fallback(initials),
              errorWidget: (_, __, ___) => _fallback(initials),
            )
          : _fallback(initials),
    );

    if (!online) return SizedBox(width: size, height: size, child: avatar);

    return Stack(
      children: [
        SizedBox(width: size, height: size, child: avatar),
        Positioned(
          bottom: 0, right: 0,
          child: Container(
            width: size * 0.28, height: size * 0.28,
            decoration: BoxDecoration(
              color: AppColors.success500,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback(String initials) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius ?? size),
      gradient: LinearGradient(
        colors: color != null
            ? [color!, Color.lerp(color!, Colors.black, 0.25)!]
            : const [AppColors.brand500, AppColors.brand800],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      initials,
      style: TextStyle(
        color: Colors.white,
        fontSize: size * 0.38,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
