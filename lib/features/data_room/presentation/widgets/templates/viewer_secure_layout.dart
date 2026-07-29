import 'package:flutter/material.dart';
import '../../../../../app/config/theme/app_theme.dart';

class ViewerSecureLayout extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;
  final Widget content;
  final List<Widget>? overlays;

  const ViewerSecureLayout({
    super.key,
    required this.title,
    this.onClose,
    required this.content,
    this.overlays,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.charcoalDeep,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose,
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            content,
            if (overlays != null) ...overlays!,
          ],
        ),
      ),
    );
  }
}
