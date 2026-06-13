import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Painter de Marcas de Agua Dinámicas.
/// Inyecta email, IP y timestamp en tiempo real sobre el documento.
/// Opacidad algorítmica disuasoria del 35%.
class DynamicWatermarkPainter extends CustomPainter {
  final String recipientEmail;
  final String ipAddress;
  final String timestamp;

  DynamicWatermarkPainter({
    required this.recipientEmail,
    required this.ipAddress,
    required this.timestamp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final watermarkText = '$recipientEmail\n$ipAddress\n$timestamp';

    final textStyle = TextStyle(
      color: Colors.grey.withOpacity(0.35),
      fontSize: 14,
      fontWeight: FontWeight.w600,
      fontFamily: 'SFMono',
      height: 1.5,
    );

    final textSpan = TextSpan(text: watermarkText, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Inyección diagonal (-45 grados) a través del lienzo
    for (double i = -size.height; i < size.width; i += textPainter.width + 100) {
      for (double j = -size.width; j < size.height; j += textPainter.height + 150) {
        canvas.save();
        canvas.translate(i + 50, j + 50);
        canvas.rotate(-math.pi / 4); // Rotación de -45 grados
        textPainter.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant DynamicWatermarkPainter oldDelegate) => false;
}

/// Widget wrapper para usar el watermark sobre cualquier contenido.
class DynamicWatermarkOverlay extends StatelessWidget {
  final Widget child;
  final String recipientEmail;
  final String ipAddress;
  final String timestamp;

  const DynamicWatermarkOverlay({
    super.key,
    required this.child,
    required this.recipientEmail,
    required this.ipAddress,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        CustomPaint(
          painter: DynamicWatermarkPainter(
            recipientEmail: recipientEmail,
            ipAddress: ipAddress,
            timestamp: timestamp,
          ),
          size: Size.infinite,
        ),
      ],
    );
  }
}
