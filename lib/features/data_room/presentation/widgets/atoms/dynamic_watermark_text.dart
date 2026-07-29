import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../app/config/theme/app_theme.dart';

class DynamicWatermarkText extends StatelessWidget {
  final String recipientEmail;
  final String recipientIp;

  const DynamicWatermarkText({
    super.key,
    required this.recipientEmail,
    required this.recipientIp,
  });

  @override
  Widget build(BuildContext context) {
    final String watermarkText =
        '$recipientEmail  •  $recipientIp  •  ${DateTime.now().toIso8601String().substring(0, 10)}';

    return IgnorePointer(
      child: Transform.rotate(
        angle: -math.pi / 6, // -30 grados
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              5,
              (index) => Text(
                watermarkText,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xB3FFFFFF), // 70% white
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
