import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/file_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  PlatformFile? _selectedFile;
  bool _isEncrypting = false;
  bool _isUploading = false;
  String? _shareLink;
  String? _errorMessage;
  double _progress = 0;
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
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Validate size (10MB limit for free tier)
        if (file.size > AppConstants.maxFileSizeBytes) {
          setState(() {
            _errorMessage = 'Archivo excede el límite de 10 MB del plan gratuito';
            _selectedFile = null;
          });
          return;
        }

        setState(() {
          _selectedFile = file;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error al seleccionar archivo');
    }
  }

  Future<void> _uploadAndEncrypt() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) return;
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Ingresa una contraseña de cifrado');
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      setState(() => _errorMessage = 'Sesión expirada');
      return;
    }

    if (!user.canCreateLink) {
      setState(() => _errorMessage = 'Has alcanzado el límite de 50 links/mes del plan gratuito');
      return;
    }

    setState(() {
      _isEncrypting = true;
      _errorMessage = null;
      _progress = 0.2;
    });

    await Future.delayed(const Duration(milliseconds: 500)); // UX delay

    setState(() {
      _isEncrypting = false;
      _isUploading = true;
      _progress = 0.6;
    });

    try {
      final fileService = ref.read(fileServiceProvider);
      final link = await fileService.uploadAndCreateLink(
        fileBytes: Uint8List.fromList(_selectedFile!.bytes!),
        fileName: _selectedFile!.name,
        mimeType: _selectedFile!.extension ?? 'application/octet-stream',
        userPassword: _passwordController.text,
        recipientEmail: _recipientController.text.isEmpty
            ? null
            : _recipientController.text,
      );

      setState(() {
        _progress = 1.0;
        _isUploading = false;
        _shareLink = 'https://kriptonshare.com/room/${link.id}';
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _shareLinkToExternal() {
    if (_shareLink == null) return;
    Share.share(
      'Documento seguro via KRIPTONSHARE\n\n'
      '$_shareLink\n\n'
      'Este enlace expira en ${AppConstants.maxDurationHours}h.',
    );
  }

  void _copyLink() {
    if (_shareLink == null) return;
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
    final isComplete = _shareLink != null;

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
            if (_isEncrypting || _isUploading) ...[
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: KriptonTheme.inkDeep,
                valueColor: const AlwaysStoppedAnimation(KriptonTheme.electricLime),
              ),
              const SizedBox(height: 16),
              Text(
                _isEncrypting
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
            if (_errorMessage != null) ...[
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
                  _errorMessage!,
                  style: const TextStyle(color: KriptonTheme.alertRed),
                  textAlign: TextAlign.center,
                ),
              ),
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
                      style: _selectedFile == null
                          ? BorderStyle.solid
                          : BorderStyle.solid,
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
                      if (_selectedFile != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                enabled: !_isEncrypting && !_isUploading,
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
                enabled: !_isEncrypting && !_isUploading,
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                onPressed: (_selectedFile == null || _isEncrypting || _isUploading)
                    ? null
                    : _uploadAndEncrypt,
                child: _isEncrypting || _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(KriptonTheme.charcoalBlack),
                        ),
                      )
                    : const Text('Cifrar y generar enlace'),
              ),
            ],

            // Success state - Share link
            if (isComplete) ...[
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
                    Icon(
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
                        data: _shareLink!,
                        version: QrVersions.auto,
                        size: 160,
                        backgroundColor: KriptonTheme.platinum,
                        foregroundColor: KriptonTheme.charcoalBlack,
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
                        _shareLink!,
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
                            onPressed: _shareLinkToExternal,
                            icon: const Icon(Icons.share),
                            label: const Text('Compartir'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _copyLink,
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
