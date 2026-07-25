import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../features/telemetry/telemetry_providers.dart';
import '../../models/kripton_file.dart';
import '../../providers/auth_provider.dart';
import '../../providers/file_provider.dart';
import '../../services/screenshot_service.dart';
import '../../utils/theme.dart';

/// Estados del visor seguro.
enum _ViewerStatus { loading, password, decrypting, viewing, error }

class ViewerScreen extends ConsumerStatefulWidget {
  final String? linkId;

  const ViewerScreen({super.key, this.linkId});

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  _ViewerStatus _status = _ViewerStatus.loading;
  String? _errorMessage;
  KriptonFile? _file;
  Uint8List? _decryptedBytes;

  final _passwordController = TextEditingController();
  final _pdfController = PdfViewerController();

  // Fallback si pdfrx no logra renderizar el PDF.
  bool _pdfRenderFailed = false;
  Timer? _pdfLoadTimer;

  // Tracking de telemetría por página.
  int? _currentPage;
  DateTime? _pageStartTime;

  @override
  void initState() {
    super.initState();
    _initializeSecureView();
    _loadFileMetadata();
    _pdfController.addListener(_onPdfPageChanged);
  }

  Future<void> _initializeSecureView() async {
    await ScreenshotService.enableSecureView();
  }

  @override
  void dispose() {
    _pdfLoadTimer?.cancel();
    _flushPageView();
    _pdfController.removeListener(_onPdfPageChanged);
    // No deshabilitamos FLAG_SECURE aquí: ahora es global para toda la app.
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadFileMetadata() async {
    final linkId = widget.linkId;
    if (linkId == null || linkId.isEmpty) {
      setState(() {
        _status = _ViewerStatus.error;
        _errorMessage = 'ID de enlace no proporcionado';
      });
      return;
    }

    final fileService = ref.read(fileServiceProvider);

    try {
      final file = await fileService.getFileByLinkId(linkId);

      if (file == null) {
        setState(() {
          _status = _ViewerStatus.error;
          _errorMessage = 'Enlace inválido, expirado o revocado';
        });
        return;
      }

      // Si el link fue enviado a un destinatario específico, restringir acceso.
      final currentUser = ref.read(authStateProvider).valueOrNull;
      final recipient = file.recipientEmail;
      if (recipient != null && recipient.isNotEmpty) {
        final currentEmail = currentUser?.email;
        if (currentEmail == null || currentEmail.toLowerCase() != recipient.toLowerCase()) {
          setState(() {
            _status = _ViewerStatus.error;
            _errorMessage =
                'Este archivo fue enviado a $recipient. Inicia sesión con esa cuenta para acceder.';
          });
          return;
        }
      }

      setState(() {
        _file = file;
        _status = _ViewerStatus.password;
      });
    } catch (e) {
      setState(() {
        _status = _ViewerStatus.error;
        _errorMessage = 'Error al cargar el documento: $e';
      });
    }
  }

  Future<void> _decryptAndView() async {
    if (_passwordController.text.isEmpty || _file == null) return;

    setState(() {
      _status = _ViewerStatus.decrypting;
      _errorMessage = null;
    });

    final fileService = ref.read(fileServiceProvider);
    final linkId = widget.linkId!;

    try {
      debugPrint('[VIEWER] Iniciando descarga y descifrado para linkId=$linkId');
      debugPrint('[VIEWER] Archivo: ${_file!.originalFilename} (${_file!.mimeType})');

      final decrypted = await fileService.downloadAndDecryptFile(
        _file!,
        _passwordController.text,
        linkId: linkId,
      );

      debugPrint('[VIEWER] Descifrado exitoso: ${decrypted.length} bytes');

      if (!mounted) return;

      setState(() {
        _decryptedBytes = decrypted;
        _pdfRenderFailed = false;
        _status = _ViewerStatus.viewing;
      });

      // Si el PDF no se renderiza en 3 segundos, ofrecer fallback externo.
      if (_file!.mimeType == 'application/pdf') {
        _pdfLoadTimer?.cancel();
        _pdfLoadTimer = Timer(const Duration(seconds: 3), () {
          if (mounted && !_pdfController.isReady) {
            debugPrint('[VIEWER] El PDF no se renderizó a tiempo, activando fallback');
            setState(() => _pdfRenderFailed = true);
          }
        });
      }

      // Reforzar FLAG_SECURE justo antes de mostrar contenido sensible.
      await ScreenshotService.enableSecureView();
      // Registrar que el receptor descifró el archivo.
      await _logEvent('download_complete');
      // Iniciar tracking de la primera página/vista.
      _startPageTracking(1);
    } on FormatException catch (e) {
      debugPrint('[VIEWER] Error de formato al descifrar: $e');
      if (mounted) {
        setState(() {
          _status = _ViewerStatus.password;
          _errorMessage = 'El archivo descifrado no es válido. Verifica la contraseña.';
        });
      }
    } on ArgumentError catch (e) {
      debugPrint('[VIEWER] Error de argumentos al descifrar: $e');
      if (mounted) {
        setState(() {
          _status = _ViewerStatus.password;
          _errorMessage = 'Datos de archivo incompletos o corruptos.';
        });
      }
    } catch (e) {
      debugPrint('[VIEWER] Error general al descifrar: $e');
      if (mounted) {
        setState(() {
          _status = _ViewerStatus.password;
          _errorMessage = 'Contraseña incorrecta o archivo corrupto';
        });
      }
    }
  }

  /// Registra un evento de telemetría silenciosamente (no falla la UI).
  Future<void> _logEvent(
    String eventType, {
    int? pageNumber,
    int durationMs = 0,
  }) async {
    final linkId = widget.linkId;
    if (linkId == null || linkId.isEmpty) return;

    try {
      await ref.read(telemetryNotifierProvider.notifier).logEvent(
        linkId: linkId,
        eventType: eventType,
        pageNumber: pageNumber,
        durationMs: durationMs,
      );
    } catch (_) {
      // Telemetría no crítica: no interrumpir la experiencia del usuario.
    }
  }

  /// Inicia el tracking de tiempo para una página.
  void _startPageTracking(int pageNumber) {
    _currentPage = pageNumber;
    _pageStartTime = DateTime.now();
  }

  /// Registra el tiempo acumulado en la página actual y reinicia para la nueva.
  void _changePage(int newPage) {
    if (_currentPage == null || _pageStartTime == null) {
      _startPageTracking(newPage);
      return;
    }
    if (_currentPage == newPage) return;

    final duration = DateTime.now().difference(_pageStartTime!).inMilliseconds;
    _logEvent('page_view', pageNumber: _currentPage, durationMs: duration);
    _startPageTracking(newPage);
  }

  /// Listener del PdfViewerController para detectar cambios de página.
  void _onPdfPageChanged() {
    final page = _pdfController.pageNumber;
    if (page != null && page > 0) {
      _changePage(page);
    }
    // Si el PDF ya renderizó, cancelamos el timer de fallback.
    if (_pdfController.isReady) {
      _pdfLoadTimer?.cancel();
      _pdfLoadTimer = null;
      if (_pdfRenderFailed && mounted) {
        setState(() => _pdfRenderFailed = false);
      }
    }
  }

  /// Registra la última página vista al cerrar el visor.
  void _flushPageView() {
    if (_currentPage == null || _pageStartTime == null) return;

    final duration = DateTime.now().difference(_pageStartTime!).inMilliseconds;
    if (duration > 0) {
      _logEvent('page_view', pageNumber: _currentPage, durationMs: duration);
    }
    _currentPage = null;
    _pageStartTime = null;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: KriptonTheme.charcoalBlack,
        appBar: AppBar(
          title: const Text('Documento seguro'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go('/dashboard'),
          ),
        ),
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _ViewerStatus.loading:
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(KriptonTheme.electricLime),
          ),
        );
      case _ViewerStatus.password:
        return _buildPasswordPrompt();
      case _ViewerStatus.decrypting:
        return _buildDecrypting();
      case _ViewerStatus.viewing:
        return _buildDocumentViewer();
      case _ViewerStatus.error:
        return _buildError();
    }
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
            'Has recibido un archivo cifrado',
            style: Theme.of(context).textTheme.displayLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_file != null) ...[
            Text(
              _file!.originalFilename,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: KriptonTheme.platinum,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${(_file!.fileSizeBytes / 1024).toStringAsFixed(1)} KB · ${_file!.mimeType}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KriptonTheme.graphite,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Ingresa la contraseña que te proporcionó el emisor para descifrarlo',
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
            onFieldSubmitted: (_) => _decryptAndView(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _decryptAndView,
            child: const Text('Descifrar y ver'),
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

  Widget _buildDecrypting() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(KriptonTheme.electricLime),
          ),
          SizedBox(height: 16),
          Text(
            'Descifrando documento...',
            style: TextStyle(color: KriptonTheme.silver),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentViewer() {
    if (_decryptedBytes == null || _file == null) {
      return const Center(
        child: Text(
          'Error inesperado',
          style: TextStyle(color: KriptonTheme.alertRed),
        ),
      );
    }

    final mimeType = _file!.mimeType;

    Widget content;
    if (mimeType.startsWith('image/')) {
      // El GestureDetector con onLongPressStart vacío intercepta el menú
      // contextual nativo de guardar/compartir imagen.
      content = InteractiveViewer(
        child: GestureDetector(
          onLongPressStart: (_) {},
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Image.memory(
              _decryptedBytes!,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    } else if (mimeType.startsWith('text/')) {
      final text = utf8.decode(_decryptedBytes!);
      content = SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: const TextStyle(
            color: KriptonTheme.platinum,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      );
    } else if (mimeType == 'application/pdf') {
      // PDF: visor nativo dentro de la app; no se permite compartir, descargar
      // ni abrir con aplicaciones externas.
      final pdfParams = PdfViewerParams(
        backgroundColor: KriptonTheme.charcoalBlack,
        errorBannerBuilder: (context, error, stackTrace, documentRef) {
          debugPrint('[VIEWER] Error renderizando PDF: $error');
          return _buildPdfFallback(
            'No se pudo abrir el PDF:\n${error.toString()}',
          );
        },
        loadingBannerBuilder: (context, bytesDownloaded, totalBytes) =>
            const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(KriptonTheme.electricLime),
          ),
        ),
      );

      if (_pdfRenderFailed) {
        content = _buildPdfFallback(
          'El visor nativo no pudo mostrar este PDF. Por seguridad no se permite abrirlo fuera de la app.',
        );
      } else {
        // Usamos PdfViewer.data para evitar problemas de URI de archivo
        // en algunos dispositivos Android.
        content = PdfViewer.data(
          key: ValueKey(_file!.id),
          _decryptedBytes!,
          sourceName: _file!.originalFilename,
          controller: _pdfController,
          useProgressiveLoading: false,
          params: pdfParams,
        );
      }
    } else {
      // Formatos no visualizables de forma segura (Word, Excel, PowerPoint, etc.)
      // No se ofrece abrir con app externa para evitar fugas de confidencialidad.
      content = Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: KriptonTheme.electricLime,
            ),
            const SizedBox(height: 24),
            Text(
              'Formato protegido',
              style: Theme.of(context).textTheme.displayLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _file!.originalFilename,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: KriptonTheme.silver,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${(_decryptedBytes!.length / 1024).toStringAsFixed(1)} KB · ${_file!.mimeType}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KriptonTheme.graphite,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              'Los documentos de Microsoft Office y otros formatos no se visualizan directamente dentro de la app por seguridad.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KriptonTheme.silver,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Para compartir este contenido de forma segura, conviértelo a PDF antes de subirlo.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KriptonTheme.platinum,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // El visor debe ocupar todo el espacio disponible.
        Positioned.fill(child: content),
        // Watermark overlay
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: CustomPaint(
                painter: WatermarkPainter(
                  text: 'KRIPTONSHARE | CONFIDENCIAL',
                  opacity: 0.18,
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

  Widget _buildPdfFallback(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.picture_as_pdf_outlined,
              size: 64,
              color: KriptonTheme.alertRed,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: KriptonTheme.silver),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: KriptonTheme.alertRed,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Error desconocido',
            style: const TextStyle(
              color: KriptonTheme.alertRed,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text('Volver al inicio'),
          ),
        ],
      ),
    );
  }
}

class WatermarkPainter extends CustomPainter {
  final String text;
  final double opacity;

  WatermarkPainter({required this.text, this.opacity = 0.15});

  @override
  void paint(Canvas canvas, Size size) {
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
