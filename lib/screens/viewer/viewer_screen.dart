import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../core/localization/formatters.dart';
import '../../features/telemetry/telemetry_providers.dart';
import '../../models/kripton_file.dart';
import '../../providers/auth_provider.dart';
import '../../providers/file_provider.dart';
import '../../services/screenshot_service.dart';
import '../../services/secure_decrypt_service.dart';
import '../../utils/theme.dart';
import '../../widgets/video_player_screen.dart';

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
  String? _decryptedFilePath;

  // Progreso real de la transferencia (descarga → descifrado).
  SecureTransferPhase _transferPhase = SecureTransferPhase.downloading;
  double _transferFraction = 0;
  int _transferPercent = 0;

  final _passwordController = TextEditingController();
  final _pdfController = PdfViewerController();

  // Fallback si pdfrx no logra renderizar el PDF.
  bool _pdfRenderFailed = false;
  Timer? _pdfLoadTimer;

  // Guard: el primer view del receptor se registra una sola vez por sesión.
  bool _firstRecipientViewLogged = false;

  // Tracking de telemetría por página.
  int? _currentPage;
  DateTime? _pageStartTime;

  @override
  void initState() {
    super.initState();
    _initializeSecureView();
    _pdfController.addListener(_onPdfPageChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFileMetadata());
  }

  Future<void> _initializeSecureView() async {
    await ScreenshotService.enableSecureView();
  }

  @override
  void dispose() {
    _pdfLoadTimer?.cancel();
    _flushPageView();
    _pdfController.removeListener(_onPdfPageChanged);
    // Borrado seguro del temporal descifrado al salir del visor.
    _deleteTempFile(_decryptedFilePath);
    // No deshabilitamos FLAG_SECURE aquí: ahora es global para toda la app.
    _passwordController.dispose();
    super.dispose();
  }

  /// Borra best-effort un archivo temporal descifrado.
  Future<void> _deleteTempFile(String? filePath) async {
    if (filePath == null) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Limpieza best-effort: nunca debe romper la salida del visor.
    }
  }

  Future<void> _loadFileMetadata() async {
    final l10n = AppLocalizations.of(context);

    final linkId = widget.linkId;
    if (linkId == null || linkId.isEmpty) {
      setState(() {
        _status = _ViewerStatus.error;
        _errorMessage = l10n.linkIdMissing;
      });
      return;
    }

    final fileService = ref.read(fileServiceProvider);

    try {
      final file = await fileService.getFileByLinkId(linkId);

      if (file == null) {
        setState(() {
          _status = _ViewerStatus.error;
          _errorMessage = l10n.linkInvalidExpiredRevoked;
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
            _errorMessage = l10n.recipientOnlyNotice(recipient);
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
        _errorMessage = l10n.documentLoadError(e.toString());
      });
    }
  }

  Future<void> _decryptAndView() async {
    if (_passwordController.text.isEmpty || _file == null) return;

    final l10n = AppLocalizations.of(context);

    setState(() {
      _status = _ViewerStatus.decrypting;
      _errorMessage = null;
      _transferPhase = SecureTransferPhase.downloading;
      _transferFraction = 0;
      _transferPercent = 0;
    });

    final fileService = ref.read(fileServiceProvider);
    final linkId = widget.linkId!;

    try {
      debugPrint('[VIEWER] Iniciando descarga y descifrado para linkId=$linkId');
      debugPrint('[VIEWER] Archivo: ${_file!.originalFilename} (${_file!.mimeType})');

      final result = await fileService.downloadAndDecryptToFile(
        _file!,
        _passwordController.text,
        linkId: linkId,
        onProgress: _onTransferProgress,
      );

      debugPrint('[VIEWER] Descifrado exitoso: ${result.plaintextBytes} bytes '
          '(download=${result.downloadMs}ms, decrypt=${result.decryptMs}ms)');

      // Los formatos con visor nativo (video/PDF) conservan el archivo en
      // disco; el resto se carga en memoria y el temporal se borra de inmediato.
      final isFileBacked = _isFileBacked(_file!.mimeType);
      Uint8List? bytes;
      String? filePath;
      if (isFileBacked) {
        filePath = result.filePath;
      } else {
        bytes = await File(result.filePath).readAsBytes();
        await _deleteTempFile(result.filePath);
      }

      if (!mounted) {
        await _deleteTempFile(filePath);
        return;
      }

      setState(() {
        _decryptedBytes = bytes;
        _decryptedFilePath = filePath;
        _pdfRenderFailed = false;
        _status = _ViewerStatus.viewing;
      });

      // Si el PDF no se renderiza en 3 segundos, ofrecer fallback.
      if (_file!.mimeType == 'application/pdf') {
        _pdfLoadTimer?.cancel();
        _pdfLoadTimer = Timer(const Duration(seconds: 3), () {
          if (mounted && !_pdfController.isReady) {
            debugPrint('[VIEWER] PDF did not render in time, enabling fallback');
            setState(() => _pdfRenderFailed = true);
          }
        });
      }

      // Reforzar FLAG_SECURE justo antes de mostrar contenido sensible.
      await ScreenshotService.enableSecureView();
      // Registrar que el receptor descifró el archivo.
      await _logEvent('download_complete');
      // Registrar primer view del receptor (funnel, RPC server-side).
      if (!_firstRecipientViewLogged) {
        _firstRecipientViewLogged = true;
        try {
          await ref
              .read(supabaseClientProvider)
              .rpc('log_first_recipient_view', params: {'p_link_id': linkId});
        } catch (e) {
          debugPrint('[VIEWER] log_first_recipient_view failed: $e');
        }
      }
      // Iniciar tracking de la primera página/vista.
      _startPageTracking(1);
    } on FileIntegrityException catch (e) {
      debugPrint('[VIEWER] Verificación de integridad fallida: $e');
      if (mounted) {
        setState(() {
          _status = _ViewerStatus.password;
          _errorMessage = l10n.viewerIntegrityError;
        });
      }
    } on FormatException catch (e) {
      debugPrint('[VIEWER] Error de formato al descifrar: $e');
      if (mounted) {
        setState(() {
          _status = _ViewerStatus.password;
          _errorMessage = l10n.invalidDecryptedFile;
        });
      }
    } on ArgumentError catch (e) {
      debugPrint('[VIEWER] Error de argumentos al descifrar: $e');
      if (mounted) {
        setState(() {
          _status = _ViewerStatus.password;
          _errorMessage = l10n.incompleteFileData;
        });
      }
    } catch (e) {
      debugPrint('[VIEWER] Error general al descifrar: $e');
      if (mounted) {
        setState(() {
          _status = _ViewerStatus.password;
          _errorMessage = l10n.wrongPasswordOrCorrupt;
        });
      }
    }
  }

  /// Formatos que se reproducen/visualizan desde su archivo temporal en disco.
  bool _isFileBacked(String mimeType) =>
      mimeType.startsWith('video/') || mimeType == 'application/pdf';

  /// Actualiza la barra de progreso sin reconstruir por cada chunk.
  void _onTransferProgress(SecureTransferProgress progress) {
    if (!mounted) return;
    if (progress.phase == _transferPhase && progress.percent == _transferPercent) {
      return;
    }
    setState(() {
      _transferPhase = progress.phase;
      _transferFraction = progress.fraction;
      _transferPercent = progress.percent;
    });
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
    final l10n = AppLocalizations.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: KriptonTheme.charcoalBlack,
        appBar: AppBar(
          title: Text(l10n.secureDocument),
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
    final l10n = AppLocalizations.of(context);

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
            l10n.encryptedFileReceived,
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
              l10n.fileSizeAndType(formatBytes(context, _file!.fileSizeBytes), _file!.mimeType),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KriptonTheme.graphite,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.senderPasswordPrompt,
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
            decoration: InputDecoration(
              labelText: l10n.decryptionPasswordLabel,
              prefixIcon: const Icon(Icons.vpn_key, color: KriptonTheme.silver),
            ),
            onFieldSubmitted: (_) => _decryptAndView(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _decryptAndView,
            child: Text(l10n.decryptAndView),
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
                    l10n.selfDestructNotice,
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
    final l10n = AppLocalizations.of(context);
    final isDownloading = _transferPhase == SecureTransferPhase.downloading;
    final label = isDownloading
        ? l10n.viewerPhaseDownloading(_transferPercent)
        : l10n.viewerPhaseDecrypting(_transferPercent);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: _transferPercent > 0 ? _transferFraction : null,
              valueColor:
                  const AlwaysStoppedAnimation(KriptonTheme.electricLime),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(color: KriptonTheme.silver),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentViewer() {
    final l10n = AppLocalizations.of(context);

    if (_file == null ||
        (_decryptedBytes == null && _decryptedFilePath == null)) {
      return Center(
        child: Text(
          l10n.unexpectedError,
          style: const TextStyle(color: KriptonTheme.alertRed),
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
      final pdfParams = PdfViewerParams(
        backgroundColor: KriptonTheme.charcoalBlack,
        errorBannerBuilder: (context, error, stackTrace, documentRef) {
          debugPrint('[VIEWER] Error renderizando PDF: $error');
          return _buildPdfFallback(
            AppLocalizations.of(context).pdfOpenError(error.toString()),
          );
        },
        loadingBannerBuilder: (context, bytesDownloaded, totalBytes) =>
            const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(KriptonTheme.electricLime),
          ),
        ),
      );

      if (_pdfRenderFailed || _decryptedFilePath == null) {
        content = _buildPdfFallback(
          l10n.pdfViewerFallback,
        );
      } else {
        // El PDF descifrado vive en un archivo temporal; pdfrx lo abre con
        // acceso aleatorio a disco en lugar de mantenerlo entero en memoria.
        content = PdfViewer.file(
          _decryptedFilePath!,
          key: ValueKey('${_file!.id}-preview'),
          controller: _pdfController,
          params: pdfParams,
        );
      }
    } else if (mimeType.startsWith('video/')) {
      // Video: se reproduce dentro de la app; el archivo temporal se elimina al cerrar.
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.videocam,
                size: 64,
                color: KriptonTheme.electricLime,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.decryptedVideo,
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _decryptedFilePath == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SecureVideoPlayerScreen(
                              filePath: _decryptedFilePath!,
                              fileName: _file!.originalFilename,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.playVideo),
              ),
            ],
          ),
        ),
      );
    } else {
      // Formatos no visualizables.
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
              l10n.protectedFormat,
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
              l10n.fileSizeAndType(formatBytes(context, _decryptedBytes!.length), _file!.mimeType),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KriptonTheme.graphite,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              l10n.officeNotViewable,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KriptonTheme.silver,
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
                  text: _file!.recipientEmail != null
                      ? l10n.confidentialUserWatermark(_file!.recipientEmail!)
                      : l10n.confidentialBanner,
                  secondaryText: DateTime.now().toIso8601String().substring(0, 16),
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
                  l10n.secureMode,
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
    final l10n = AppLocalizations.of(context);

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
              child: Text(l10n.backToHome),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    final l10n = AppLocalizations.of(context);

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
            _errorMessage ?? l10n.unknownError,
            style: const TextStyle(
              color: KriptonTheme.alertRed,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/dashboard'),
            child: Text(l10n.backToHome),
          ),
        ],
      ),
    );
  }
}

class WatermarkPainter extends CustomPainter {
  final String text;
  final String? secondaryText;
  final double opacity;

  WatermarkPainter({
    required this.text,
    this.secondaryText,
    this.opacity = 0.15,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final primaryStyle = TextStyle(
      color: Colors.white.withOpacity(opacity),
      fontSize: 24,
      fontWeight: FontWeight.w500,
    );

    final secondaryStyle = TextStyle(
      color: Colors.white.withOpacity(opacity * 0.8),
      fontSize: 14,
      fontWeight: FontWeight.w400,
    );

    final primaryPainter = TextPainter(
      text: TextSpan(text: text, style: primaryStyle),
      textDirection: TextDirection.ltr,
    );

    final secondaryPainter = secondaryText != null
        ? TextPainter(
            text: TextSpan(text: secondaryText, style: secondaryStyle),
            textDirection: TextDirection.ltr,
          )
        : null;

    // Draw diagonal watermarks
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 3; j++) {
        canvas.save();
        canvas.translate(
          i * size.width / 5 + 50,
          j * size.height / 3 + 50,
        );
        canvas.rotate(-45 * 3.14159265359 / 180);

        primaryPainter.layout(maxWidth: 300);
        primaryPainter.paint(canvas, Offset.zero);

        if (secondaryPainter != null) {
          secondaryPainter.layout(maxWidth: 300);
          secondaryPainter.paint(canvas, Offset(0, primaryPainter.height + 4));
        }

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
