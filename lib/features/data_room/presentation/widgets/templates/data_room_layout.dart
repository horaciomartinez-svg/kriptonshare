import 'package:flutter/material.dart';
import '../../../../../app/config/theme/app_theme.dart';
import '../molecules/storage_gauge_card.dart';

class DataRoomLayout extends StatelessWidget {
  final String title;
  final int usedBytes;
  final int maxBytes;
  final VoidCallback? onUpgradeStorage;
  final List<Widget> actions;
  final Widget body;

  const DataRoomLayout({
    super.key,
    required this.title,
    required this.usedBytes,
    required this.maxBytes,
    this.onUpgradeStorage,
    required this.actions,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.charcoalDeep,
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: StorageGaugeCard(
                usedBytes: usedBytes,
                maxBytes: maxBytes,
                onUpgrade: onUpgradeStorage,
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
