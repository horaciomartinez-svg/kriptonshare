import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import '../utils/theme.dart';

/// Reproductor de video seguro para contenido descifrado.
///
/// Escribe los bytes descifrados a un archivo temporal privado, lo reproduce
/// con el reproductor nativo y elimina el archivo temporal al cerrarse.
class SecureVideoPlayerScreen extends StatefulWidget {
  final Uint8List videoBytes;
  final String fileName;

  const SecureVideoPlayerScreen({
    super.key,
    required this.videoBytes,
    required this.fileName,
  });

  @override
  State<SecureVideoPlayerScreen> createState() =>
      _SecureVideoPlayerScreenState();
}

class _SecureVideoPlayerScreenState extends State<SecureVideoPlayerScreen> {
  VideoPlayerController? _controller;
  File? _tempFile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final l10n = AppLocalizations.of(context);
    try {
      final tempDir = await getTemporaryDirectory();
      final safeName = path.basenameWithoutExtension(widget.fileName);
      final ext = path.extension(widget.fileName);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$safeName$ext';
      _tempFile = File(path.join(tempDir.path, fileName));
      await _tempFile!.writeAsBytes(widget.videoBytes, flush: true);

      _controller = VideoPlayerController.file(_tempFile!);
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.play();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = l10n.videoPlaybackError(e.toString());
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _deleteTempFile();
    super.dispose();
  }

  Future<void> _deleteTempFile() async {
    try {
      if (_tempFile != null && await _tempFile!.exists()) {
        await _tempFile!.delete();
      }
    } catch (_) {
      // Limpieza best-effort.
    }
  }

  @override
  Widget build(BuildContext context) {
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
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(KriptonTheme.electricLime),
                )
              : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: KriptonTheme.alertRed),
                        textAlign: TextAlign.center,
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
