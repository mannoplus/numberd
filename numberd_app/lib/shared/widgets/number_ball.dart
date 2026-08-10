import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/colors.dart';

enum NumberBallVariant {
  normal,
  hot,
  cold,
  dimmed,
  special // e.g., the second zone in SuperLotto
}

class NumberBall extends StatelessWidget {
  final int number;
  final NumberBallVariant variant;
  final double size;

  const NumberBall({
    super.key,
    required this.number,
    this.variant = NumberBallVariant.normal,
    this.size = 40.0,
  });

  Color _getBackgroundColor() {
    switch (variant) {
      case NumberBallVariant.normal:
        return AppColors.surfaceLight;
      case NumberBallVariant.hot:
        return AppColors.hot.withAlpha(38);
      case NumberBallVariant.cold:
        return AppColors.cold.withAlpha(38);
      case NumberBallVariant.dimmed:
        return AppColors.background;
      case NumberBallVariant.special:
        return AppColors.primary.withAlpha(38);
    }
  }

  Color _getBorderColor() {
    switch (variant) {
      case NumberBallVariant.normal:
        return AppColors.border;
      case NumberBallVariant.hot:
        return AppColors.hot.withAlpha(127);
      case NumberBallVariant.cold:
        return AppColors.cold.withAlpha(127);
      case NumberBallVariant.dimmed:
        return AppColors.border.withAlpha(76);
      case NumberBallVariant.special:
        return AppColors.primary;
    }
  }

  Color _getTextColor() {
    switch (variant) {
      case NumberBallVariant.normal:
        return AppColors.textPrimary;
      case NumberBallVariant.hot:
        return AppColors.hot;
      case NumberBallVariant.cold:
        return AppColors.cold;
      case NumberBallVariant.dimmed:
        return AppColors.textMuted;
      case NumberBallVariant.special:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        shape: BoxShape.circle,
        border: Border.all(
          color: _getBorderColor(),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        number.toString().padLeft(2, '0'),
        style: GoogleFonts.inter(
          color: _getTextColor(),
          fontSize: size * 0.45,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
