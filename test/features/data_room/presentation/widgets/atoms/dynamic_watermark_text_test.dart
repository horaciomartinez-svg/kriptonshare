import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/features/data_room/presentation/widgets/atoms/dynamic_watermark_text.dart';

void main() {
  testWidgets('DynamicWatermarkText muestra email e IP', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DynamicWatermarkText(
            recipientEmail: 'inversor@fondo.com',
            recipientIp: '192.168.1.45',
          ),
        ),
      ),
    );

    expect(find.textContaining('inversor@fondo.com'), findsWidgets);
    expect(find.textContaining('192.168.1.45'), findsWidgets);
  });
}
