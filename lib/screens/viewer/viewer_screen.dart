import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/kripton_file.dart';
import '../../services/screenshot_service.dart';
import '../../utils/theme.dart';

class ViewerScreen extends ConsumerStatefulWidget {
  final String? linkId;

  const ViewerScreen({super.key, this.linkId});

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  bool _isLoading = true;
  bool _isDecrypting = false;
  String? _errorMessage;
  KriptonFile? _file;
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeSecureView();
    _loadFile();
  }

  Future<void> _initializeSecureView() async {
    await ScreenshotService.enableSecureView();
  }

  @override
  void dispose() {
    ScreenshotService.disableSecureView();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadFile() async {
    if (widget.linkId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ID de enlace no proporcionado';
      });
      return;
    }

    // TODO: Load file from link ID via API
    // For now, simulate loading
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  Future<void> _decryptAndView() async {
    if (_passwordController.text.isEmpty) return;

    setState(() {
      _isDecrypting = true;
      _errorMessage = null;
    });

    // TODO: Download encrypted file, decrypt, and render
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isDecrypting = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: KriptonTheme.charcoalBlack,
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(KriptonTheme.electricLime),
                  ),
                )
              : _file == null
                  ? _buildPasswordPrompt()
                  : _buildDocumentViewer(),
        ),
      ),
    );
  }

  Widget _buildPasswordPrompt() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: KriptonTheme.electricLime.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Documento cifrado',
            style: Theme.of(context).textTheme.displayLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa la contraseña proporcionada por el emisor',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: KriptonTheme.silver,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: KriptonTheme.platinum),
            decoration: const InputDecoration(
              labelText: 'Contraseña de descifrado',
              prefixIcon: Icon(Icons.vpn_key, color: KriptonTheme.silver),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isDecrypting ? null : _decryptAndView,
            child: _isDecrypting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(KriptonTheme.charcoalBlack),
                    ),
                  )
                : const Text('Descifrar y ver'),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: KriptonTheme.alertRed),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KriptonTheme.inkDeep,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: KriptonTheme.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Este documento se autodestruye tras la caducidad. No se almacena en tu dispositivo.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KriptonTheme.silver,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentViewer() {
    // TODO: Implement PDF/image viewer with watermark
    return Stack(
      children: [
        // Document content would go here
        const Center(
          child: Text(
            'Visor de documento',
            style: TextStyle(color: KriptonTheme.platinum),
          ),
        ),
        // Watermark overlay
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
              ),
              child: CustomPaint(
                painter: WatermarkPainter(
                  text: 'KRIPTONSHARE | CONFIDENCIAL',
                  opacity: 0.15,
                ),
              ),
            ),
          ),
        ),
        // Security indicator
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: KriptonTheme.alertRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: KriptonTheme.alertRed,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'MODO SEGURO',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: KriptonTheme.alertRed,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class WatermarkPainter extends CustomPainter {
  final String text;
  final double opacity;

  WatermarkPainter({required this.text, this.opacity = 0.15});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final textStyle = TextStyle(
      color: Colors.white.withOpacity(opacity),
      fontSize: 24,
      fontWeight: FontWeight.w500,
    );

    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    // Draw diagonal watermarks
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 3; j++) {
        canvas.save();
        canvas.translate(
          i * size.width / 5 + 50,
          j * size.height / 3 + 50,
        );
        canvas.rotate(-45 * 3.14159265359 / 180);
        textPainter.layout(maxWidth: 200);
        textPainter.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
