import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class PieChartWidget extends StatelessWidget {
  final Map<String, int> data;
  final Map<String, Color> colors;
  final double size;

  const PieChartWidget({
    Key? key,
    required this.data,
    required this.colors,
    this.size = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<int>(0, (sum, value) => sum + value);
    
    if (total == 0) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            'НЕТ ДАННЫХ',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.mistGray,
              letterSpacing: 2.0,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _PieChartPainter(
              data: data,
              colors: colors,
              total: total,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: data.entries.map((entry) {
        final color = colors[entry.key] ?? AppTheme.mistGray;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${entry.key}: ${entry.value}',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.ashGray,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<String, int> data;
  final Map<String, Color> colors;
  final int total;

  _PieChartPainter({
    required this.data,
    required this.colors,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    double startAngle = -math.pi / 2; // Start from top

    data.forEach((key, value) {
      final sweepAngle = (value / total) * 2 * math.pi;
      final color = colors[key] ?? AppTheme.mistGray;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // Draw pie slice
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = AppTheme.deepBlack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    });

    // Draw center circle for donut effect
    final centerPaint = Paint()
      ..color = AppTheme.midnightBlack
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, centerPaint);

    // Draw center border
    final centerBorderPaint = Paint()
      ..color = AppTheme.shadowGray
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius * 0.5, centerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

