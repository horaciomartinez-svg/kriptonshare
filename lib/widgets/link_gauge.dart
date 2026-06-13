import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/theme.dart';

class LinkGauge extends StatelessWidget {
  final int used;
  final int total;

  const LinkGauge({
    super.key,
    required this.used,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = total - used;
    final percentage = used / total;
    final color = percentage < 0.6
        ? KriptonTheme.electricLime
        : percentage < 0.8
            ? KriptonTheme.amber
            : KriptonTheme.alertRed;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KriptonTheme.ink,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: KriptonTheme.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enlaces mensuales',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '$used / $total',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontSize: 14,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(120, 120),
              painter: CircularGaugePainter(
                percentage: percentage,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$remaining restantes',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 18,
                  color: color,
                ),
          ),
          Text(
            'Plan gratuito',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: KriptonTheme.graphite,
                ),
          ),
        ],
      ),
    );
  }
}

class CircularGaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  CircularGaugePainter({
    required this.percentage,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final strokeWidth = 8.0;

    // Background circle
    final bgPaint = Paint()
      ..color = KriptonTheme.inkDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          color.withOpacity(0.5),
          color,
        ],
        startAngle: 0,
        endAngle: math.pi * 2 * percentage,
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * percentage,
      false,
      progressPaint,
    );

    // Center text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(percentage * 100).toInt()}%',
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
