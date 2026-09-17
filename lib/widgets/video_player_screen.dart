import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import '../utils/theme.dart';

/// Reproductor de video seguro para contenido descifrado.
///
/// Recibe la ruta del archivo temporal **ya descifrado** (con su extensión
/// original, p. ej. `.mp4`) y lo reproduce con el reproductor nativo. El
/// archivo lo posee el visor, que lo elimina al salir; este widget nunca
/// vuelve a copiar el contenido en memoria.
class SecureVideoPlayerScreen extends StatefulWidget {
  final String filePath;
  final String fileName;

  const SecureVideoPlayerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  State<SecureVideoPlayerScreen> createState() =>
      _SecureVideoPlayerScreenState();
}

class _SecureVideoPlayerScreenState extends State<SecureVideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _error;
  String? _errorDetail;

  /// Solo se rellena si tuvimos que copiar el archivo (fuera de tempDir); esa
  /// copia descifrada es nuestra y hay que borrarla al salir.
  File? _ownedCopy;

  /// Evita reinicializar en reconstrucciones posteriores.
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    // Nada que dependa de context aquí: los inherited widgets (localizaciones,
    // tema, media query) no están disponibles durante initState. La
    // inicialización real ocurre en didChangeDependencies.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final l10n = AppLocalizations.of(context);
    final stopwatch = Stopwatch()..start();
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        throw Exception('decrypted video file is missing');
      }

      // Garantiza que el archivo temporal vive en el directorio privado de la
      // app (aunque el visor ya lo creó ahí) y conserva la extensión original.
      final tempDir = await getTemporaryDirectory();
      final resolved = path.isWithin(tempDir.path, file.path)
          ? file
          : File(path.join(
              tempDir.path,
              '${DateTime.now().millisecondsSinceEpoch}'
                  '_${path.basename(widget.filePath)}',
            ));
      if (resolved.path != file.path) {
        await file.copy(resolved.path);
        _ownedCopy = resolved;
      }

      final controller = VideoPlayerController.file(resolved);
      _controller = controller;
      controller.addListener(_onControllerChanged);

      await controller.initialize();
      stopwatch.stop();
      debugPrint('[PLAYER-PERF] init: ${stopwatch.elapsedMilliseconds}ms '
          '(file=${path.basename(resolved.path)})');

      if (controller.value.hasError) {
        throw Exception(
          controller.value.errorDescription ?? 'unknown player error',
        );
      }

      await controller.setLooping(true);
      await controller.play();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint('[PLAYER-PERF] init failed after '
          '${stopwatch.elapsedMilliseconds}ms: $e');
      final controller = _controller;
      if (controller != null && controller.value.hasError) {
        debugPrint('[PLAYER-PERF] controller errorDescription: '
            '${controller.value.errorDescription}');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = l10n.videoPlayerOpenError;
          _errorDetail = e.toString();
        });
      }
    }
  }

  /// Captura errores asíncronos reportados por el reproductor nativo una vez
  /// que la reproducción ya arrancó.
  void _onControllerChanged() {
    final controller = _controller;
    if (controller == null || !mounted || _error != null) return;
    if (controller.value.hasError) {
      final description =
          controller.value.errorDescription ?? 'unknown player error';
      debugPrint('[PLAYER-PERF] controller error: $description');
      setState(() {
        _isLoading = false;
        _error = AppLocalizations.of(context).videoPlayerOpenError;
        _errorDetail = description;
      });
    }
  }

  Future<void> _retry() async {
    final old = _controller;
    _controller = null;
    if (old != null) {
      old.removeListener(_onControllerChanged);
      await old.dispose();
    }
    await _deleteOwnedCopy();
    _ownedCopy = null;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _errorDetail = null;
    });
    await _initPlayer();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    _deleteOwnedCopy();
    super.dispose();
  }

  /// Borra la copia descifrada que creó este widget (si la hubo). El archivo
  /// original lo posee el visor, que lo elimina al salir.
  Future<void> _deleteOwnedCopy() async {
    try {
      final copy = _ownedCopy;
      if (copy != null && await copy.exists()) {
        await copy.delete();
      }
    } catch (_) {
      // Limpieza best-effort.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      appBar: AppBar(
        title: Text(widget.fileName),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(KriptonTheme.electricLime),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.viewerPreparingVideo,
                      style: const TextStyle(color: KriptonTheme.silver),
                    ),
                  ],
                )
              : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: KriptonTheme.alertRed,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: KriptonTheme.alertRed,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_errorDetail != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _errorDetail!,
                              style: const TextStyle(
                                color: KriptonTheme.graphite,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.retry),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              l10n.backToHome,
                              style: const TextStyle(
                                color: KriptonTheme.silver,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          VideoPlayer(_controller!),
                          _ControlsOverlay(controller: _controller!),
                          VideoProgressIndicator(
                            _controller!,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: KriptonTheme.electricLime,
                              bufferedColor: KriptonTheme.silver,
                              backgroundColor: KriptonTheme.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

class _ControlsOverlay extends StatefulWidget {
  final VideoPlayerController controller;

  const _ControlsOverlay({required this.controller});

  @override
  State<_ControlsOverlay> createState() => _ControlsOverlayState();
}

class _ControlsOverlayState extends State<_ControlsOverlay> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.controller.value.isPlaying
              ? widget.controller.pause()
              : widget.controller.play();
        });
      },
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: widget.controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KriptonTheme.electricLime.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: KriptonTheme.electricLime,
                    size: 48,
                  ),
                ),
        ),
      ),
    );
  }
}
