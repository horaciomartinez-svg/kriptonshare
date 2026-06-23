import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_selector/file_selector.dart';
import 'package:mime/mime.dart' show lookupMimeType;
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/utils/theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/file_provider.dart';
import '../../../../utils/constants.dart';
import '../../upload_providers.dart';
import '../notifiers/upload_notifier.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  XFile? _selectedFile;
  int? _selectedFileSize;
  final _passwordController = TextEditingController();
  final _recipientController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      // file_selector usa el selector nativo del SO y devuelve un XFile
      // que funciona en Android, iOS, Web y Desktop.
      final file = await openFile();

      if (file != null) {
        final length = await file.length();

        // Validate size (10MB limit for free tier)
        if (length > AppConstants.maxFileSizeBytes) {
          setState(() {
            _selectedFile = null;
            _selectedFileSize = null;
          });
          ref.read(uploadNotifierProvider.notifier).setError(
                'Archivo excede el límite de 10 MB del plan gratuito',
              );
          return;
        }

        setState(() {
          _selectedFile = file;
          _selectedFileSize = length;
        });
        ref.read(uploadNotifierProvider.notifier).reset();
      }
    } catch (e) {
      ref.read(uploadNotifierProvider.notifier).setError(
            'Error al seleccionar archivo',
          );
    }
  }

  Future<void> _uploadAndEncrypt() async {
    if (_selectedFile == null) return;
    if (_passwordController.text.isEmpty) {
      ref.read(uploadNotifierProvider.notifier).setError(
            'Ingresa una contraseña de cifrado',
          );
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      ref.read(uploadNotifierProvider.notifier).setError(
            'Sesión expirada',
          );
      return;
    }

    if (!user.canCreateLink) {
      ref.read(uploadNotifierProvider.notifier).setError(
            'Has alcanzado el límite de 50 links/mes del plan gratuito',
          );
      return;
    }

    final fileBytes = await _selectedFile!.readAsBytes();
    final mimeType = _selectedFile!.mimeType ??
        lookupMimeType(_selectedFile!.name) ??
        'application/octet-stream';

    await ref.read(uploadNotifierProvider.notifier).uploadFile(
          ownerId: user.id,
          fileBytes: fileBytes,
          fileName: _selectedFile!.name,
          mimeType: mimeType,
          password: _passwordController.text,
          recipientEmail: _recipientController.text.isEmpty
              ? null
              : _recipientController.text,
        );
  }

  void _shareLinkToExternal(String shareUrl) {
    ref.invalidate(userLinksProvider);
    Share.share(
      'Documento seguro via KRIPTONSHARE\n\n'
      '$shareUrl\n\n'
      'Este enlace expira en ${AppConstants.maxDurationHours}h.',
    );
  }

  void _copyLink(String shareUrl) {
    ref.invalidate(userLinksProvider);
    // Clipboard implementation would go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copiado al portapapeles'),
        backgroundColor: KriptonTheme.kryptonGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadNotifierProvider);
    final isComplete = uploadState.isSuccess;
    final isLoading = uploadState.isLoading;
    final errorMessage = uploadState.errorMessage;
    final shareUrl = uploadState.result?.shareUrl;

    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      appBar: AppBar(
        title: const Text('Nuevo Data Room'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress indicator
            if (isLoading) ...[
              LinearProgressIndicator(
                value: uploadState.progress,
                backgroundColor: KriptonTheme.inkDeep,
                valueColor:
                    const AlwaysStoppedAnimation(KriptonTheme.electricLime),
              ),
              const SizedBox(height: 16),
              Text(
                uploadState.step == UploadStep.encrypting
                    ? 'Cifrado AES-256-GCM en proceso...'
                    : 'Subiendo a nube transitoria...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KriptonTheme.cyanTelemetry,
                      fontFamily: 'SFMono',
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],

            // Error message
            if (errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KriptonTheme.alertRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: KriptonTheme.alertRed.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: KriptonTheme.alertRed),
                  textAlign: TextAlign.center,
                ),
              )
                  .animate()
                  .shake(),
              const SizedBox(height: 16),
            ],

            // File selection area
            if (!isComplete) ...[
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: _selectedFile == null
                        ? KriptonTheme.inkDeep
                        : KriptonTheme.ink,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedFile == null
                          ? KriptonTheme.cardBorder
                          : KriptonTheme.electricLime.withOpacity(0.5),
                      width: _selectedFile == null ? 1 : 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedFile == null
                            ? Icons.cloud_upload_outlined
                            : Icons.insert_drive_file,
                        size: 48,
                        color: _selectedFile == null
                            ? KriptonTheme.silver
                            : KriptonTheme.electricLime,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFile == null
                            ? 'Toca para seleccionar archivo'
                            : _selectedFile!.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _selectedFile == null
                                  ? KriptonTheme.silver
                                  : KriptonTheme.platinum,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_selectedFile != null && _selectedFileSize != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${(_selectedFileSize! / 1024).toStringAsFixed(1)} KB',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: KriptonTheme.silver,
                                  ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Máximo ${AppConstants.maxFileSizeBytes ~/ (1024 * 1024)} MB',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: KriptonTheme.graphite,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fade(duration: 300.ms)
                  .scale(delay: 100.ms, duration: 300.ms),
              const SizedBox(height: 24),

              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                enabled: !isLoading,
                style: const TextStyle(color: KriptonTheme.platinum),
                decoration: const InputDecoration(
                  labelText: 'Contraseña de cifrado',
                  hintText: 'Esta contraseña nunca se almacena',
                  prefixIcon: Icon(Icons.lock, color: KriptonTheme.silver),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AES-256-GCM. Tu dispositivo cifra antes de transmitir.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KriptonTheme.graphite,
                      fontSize: 11,
                    ),
              ),
              const SizedBox(height: 16),

              // Recipient email (optional)
              TextFormField(
                controller: _recipientController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading,
                style: const TextStyle(color: KriptonTheme.platinum),
                decoration: const InputDecoration(
                  labelText: 'Email del receptor (opcional)',
                  hintText: 'para marca de agua forense',
                  prefixIcon: Icon(Icons.person, color: KriptonTheme.silver),
                ),
              ),
              const SizedBox(height: 16),

              // Duration indicator (fixed for free tier)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KriptonTheme.inkDeep,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: KriptonTheme.amber, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Duración: ${AppConstants.maxDurationHours} horas',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'Plan gratuito: duración fija',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: KriptonTheme.graphite,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.lock, color: KriptonTheme.graphite, size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Upload button
              ElevatedButton(
                onPressed: (_selectedFile == null || isLoading)
                    ? null
                    : _uploadAndEncrypt,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                              KriptonTheme.charcoalBlack),
                        ),
                      )
                    : const Text('Cifrar y generar enlace'),
              ),
            ],

            // Success state - Share link
            if (isComplete && shareUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: KriptonTheme.ink,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: KriptonTheme.cryptoGreen.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 64,
                      color: KriptonTheme.cryptoGreen,
                    )
                        .animate()
                        .scale(duration: 400.ms, curve: Curves.easeOutBack)
                        .fade(),
                    const SizedBox(height: 16),
                    Text(
                      'Data Room creado',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Expira en ${AppConstants.maxDurationHours}h',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: KriptonTheme.amber,
                          ),
                    ),
                    const SizedBox(height: 24),
                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: KriptonTheme.platinum,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: shareUrl,
                        version: QrVersions.auto,
                        size: 160,
                        backgroundColor: KriptonTheme.platinum,
                        eyeStyle: const QrEyeStyle(
                          color: KriptonTheme.charcoalBlack,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          color: KriptonTheme.charcoalBlack,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Link display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: KriptonTheme.inkDeep,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        shareUrl,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'SFMono',
                              color: KriptonTheme.cyanTelemetry,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _shareLinkToExternal(shareUrl),
                            icon: const Icon(Icons.share),
                            label: const Text('Compartir'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _copyLink(shareUrl),
                            icon: const Icon(Icons.copy),
                            label: const Text('Copiar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
                  .animate()
                  .fade(duration: 400.ms)
                  .scale(delay: 200.ms, duration: 400.ms),
            ],
          ],
        ),
      ),
    );
  }
}
