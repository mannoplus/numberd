import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class NavIcon extends StatelessWidget {
  final int index;
  final bool isSelected;

  const NavIcon({
    super.key,
    required this.index,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textMuted;
    
    return CustomPaint(
      size: const Size(22, 22),
      painter: _NavIconPainter(index: index, isSelected: isSelected, color: color),
    );
  }
}

class _NavIconPainter extends CustomPainter {
  final int index;
  final bool isSelected;
  final Color color;

  _NavIconPainter({
    required this.index,
    required this.isSelected,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = isSelected ? color : color.withAlpha(50)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    switch (index) {
      case 0:
        // Dashboard: Geometric dashboard card grid
        final rect1 = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w * 0.45, h * 0.45), const Radius.circular(2));
        final rect2 = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.55, 0, w * 0.45, h * 0.45), const Radius.circular(2));
        final rect3 = RRect.fromRectAndRadius(Rect.fromLTWH(0, h * 0.55, w, h * 0.45), const Radius.circular(2));
        canvas.drawRRect(rect1, isSelected ? fillPaint : strokePaint);
        canvas.drawRRect(rect2, strokePaint);
        canvas.drawRRect(rect3, strokePaint);
        break;

      case 1:
        // Predict: AI Forecast Spark / Matrix Pulse
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.22, isSelected ? fillPaint : strokePaint);
        canvas.drawLine(Offset(w * 0.5, 0), Offset(w * 0.5, h * 0.2), strokePaint);
        canvas.drawLine(Offset(w * 0.5, h * 0.8), Offset(w * 0.5, h), strokePaint);
        canvas.drawLine(Offset(0, h * 0.5), Offset(w * 0.2, h * 0.5), strokePaint);
        canvas.drawLine(Offset(w * 0.8, h * 0.5), Offset(w, h * 0.5), strokePaint);
        break;

      case 2:
        // Stats / Analysis: Histogram Bars with Peak Bar
        final b1 = Rect.fromLTWH(w * 0.05, h * 0.55, w * 0.22, h * 0.45);
        final b2 = Rect.fromLTWH(w * 0.38, h * 0.15, w * 0.22, h * 0.85);
        final b3 = Rect.fromLTWH(w * 0.71, h * 0.35, w * 0.22, h * 0.65);
        canvas.drawRect(b1, strokePaint);
        canvas.drawRect(b2, isSelected ? fillPaint : strokePaint);
        canvas.drawRect(b3, strokePaint);
        break;

      case 3:
        // History: Ledger lines with ball indicator
        canvas.drawCircle(Offset(w * 0.2, h * 0.25), w * 0.12, isSelected ? fillPaint : strokePaint);
        canvas.drawLine(Offset(w * 0.45, h * 0.25), Offset(w, h * 0.25), strokePaint);
        
        canvas.drawCircle(Offset(w * 0.2, h * 0.6), w * 0.12, strokePaint);
        canvas.drawLine(Offset(w * 0.45, h * 0.6), Offset(w, h * 0.6), strokePaint);
        
        canvas.drawCircle(Offset(w * 0.2, h * 0.95), w * 0.12, strokePaint);
        canvas.drawLine(Offset(w * 0.45, h * 0.95), Offset(w, h * 0.95), strokePaint);
        break;

      case 4:
        // Picker / Combinatorial: Geometric 3x3 ball grid
        for (int r = 0; r < 2; r++) {
          for (int c = 0; c < 2; c++) {
            final cx = w * 0.25 + c * w * 0.5;
            final cy = h * 0.25 + r * h * 0.5;
            if (r == 0 && c == 0 && isSelected) {
              canvas.drawCircle(Offset(cx, cy), w * 0.18, fillPaint);
            } else {
              canvas.drawCircle(Offset(cx, cy), w * 0.18, strokePaint);
            }
          }
        }
        break;

      default:
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NavIconPainter oldDelegate) {
    return oldDelegate.index != index || oldDelegate.isSelected != isSelected || oldDelegate.color != color;
  }
}
