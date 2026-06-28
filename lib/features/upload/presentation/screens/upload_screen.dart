// lib/features/upload/presentation/screens/upload_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_selector/file_selector.dart';
import 'package:mime/mime.dart' show lookupMimeType;
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/file_provider.dart';
import '../../../../utils/theme.dart';
import '../../../../utils/constants.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  XFile? _selectedFile;
  int? _selectedFileSize;
  bool _isEncrypting = false;
  bool _isUploading = false;
  String? _shareLink;
  String? _errorMessage;
  double _progress = 0;
  
  // Aguja del Slider: Inicializa estrictamente en 24 horas por defecto
  double _selectedDurationHours = AppConstants.defaultDurationHours.toDouble();
  
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
      final file = await openFile();
      if (file != null) {
        final length = await file.length();
        if (length > AppConstants.maxFileSizeBytes) {
          setState(() {
            _selectedFile = null;
            _selectedFileSize = null;
            _errorMessage = 'El archivo excede el límite de 10 MB del plan gratuito';
          });
          return;
        }
        setState(() {
          _selectedFile = file;
          _selectedFileSize = length;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error al seleccionar archivo');
    }
  }

  Future<void> _uploadAndEncrypt() async {
    if (_selectedFile == null) return;
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Ingresa una contraseña de cifrado');
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      setState(() => _errorMessage = 'Sesión expirada');
      return;
    }

    setState(() {
      _isEncrypting = true;
      _errorMessage = null;
      _progress = 0.2;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      _isEncrypting = false;
      _isUploading = true;
      _progress = 0.7;
    });

    try {
      final fileBytes = await _selectedFile!.readAsBytes();
      final mimeType = _selectedFile!.mimeType ?? lookupMimeType(_selectedFile!.name) ?? 'application/octet-stream';
      
      final fileService = ref.read(fileServiceProvider);
      final link = await fileService.uploadAndCreateLink(
        fileBytes: fileBytes,
        fileName: _selectedFile!.name,
        mimeType: mimeType,
        userPassword: _passwordController.text,
        selectedDurationHours: _selectedDurationHours.toInt(), // Inyección del slider
        recipientEmail: _recipientController.text.isEmpty ? null : _recipientController.text,
      );

      setState(() {
        _progress = 1.0;
        _isUploading = false;
        _shareLink = AppConstants.shareUrl(link.id);
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isEncrypting = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _shareLinkToExternal(String url) {
    ref.invalidate(userLinksProvider);
    Share.share('Documento seguro via KRIPTONSHARE\n\n$url\n\nEste enlace expira en ${_selectedDurationHours.toInt()}h.');
  }

  // === COMPONENTE COMPACTO DEL SLIDER INTERACTIVO ===
  Widget _buildInteractiveDurationSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KriptonTheme.inkDeep,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius.toDouble()),
        border: Border.all(color: KriptonTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Expiración:', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: KriptonTheme.charcoalBlack,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: KriptonTheme.electricLime.withOpacity(0.5)),
                ),
                child: Text(
                  '${_selectedDurationHours.toInt()}h',
                  style: const TextStyle(color: KriptonTheme.electricLime, fontFamily: 'SFMono', fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: KriptonTheme.electricLime,
              inactiveTrackColor: KriptonTheme.cardBorder,
              thumbColor: KriptonTheme.electricLime,
              overlayColor: KriptonTheme.electricLime.withOpacity(0.12),
            ),
            child: Slider(
              value: _selectedDurationHours,
              min: 1.0,
              max: AppConstants.maxDurationHours.toDouble(), // 48.0 Estricto
              divisions: 47,
              label: '${_selectedDurationHours.toInt()}h',
              onChanged: (_isEncrypting || _isUploading) ? null : (value) {
                setState(() => _selectedDurationHours = value);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 hora', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: KriptonTheme.graphite)),
              Text('24h (Defecto)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: KriptonTheme.graphite, fontSize: 10)),
              Text('48 horas (Máx)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: KriptonTheme.graphite)),
            ],
          ),
        ],
      ),
    );
  }

  // === ESQUELETO PUBLICITARIO MIGRADO (40% / 40% / 20%) ===
  Widget _buildProcessingAdOverlay() {
    return Container(
      color: KriptonTheme.charcoalBlack,
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      padding: const EdgeInsets.all(24) + MediaQuery.of(context).padding,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical - 48,
          ),
          child: IntrinsicHeight(
            child: Column(
              children: [
                // 40% Superior: Zona de Autoridad
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, size: 48, color: KriptonTheme.electricLime)
                          .animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms),
                      const SizedBox(height: 12),
                      const Text('Protegiendo tus archivos...', style: TextStyle(color: KriptonTheme.platinum, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: KriptonTheme.inkDeep,
                        valueColor: const AlwaysStoppedAnimation(KriptonTheme.electricLime),
                      ),
                      const SizedBox(height: 10),
                      Text(_isEncrypting ? '> Cifrando con AES-256...' : '> Sincronizando en R2...',
                        style: const TextStyle(color: KriptonTheme.cyanTelemetry, fontFamily: 'SFMono', fontSize: 11),
                      ),
                    ],
                  ),
                ),

                // 40% Central: Zona de Anuncio Nativo B2B
                Expanded(
                  flex: 4,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      border: Border.all(color: KriptonTheme.cardBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 40, height: 40, color: KriptonTheme.ink, child: const Icon(Icons.business, color: KriptonTheme.silver, size: 20)),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('IBM Cloud Security', style: TextStyle(color: KriptonTheme.platinum, fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Protege la infraestructura de tu empresa.', style: TextStyle(color: KriptonTheme.silver, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: KriptonTheme.silver,
                            side: const BorderSide(color: KriptonTheme.graphite),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('CONOCER MÁS', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ),

                // 20% Inferior: Zona de Escape (Upsell)
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿Envíos sin pausas?', style: TextStyle(color: KriptonTheme.silver, fontSize: 11)),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text('> Ve a Premium', style: TextStyle(color: KriptonTheme.platinum, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _shareLink != null;
    if (_isEncrypting || _isUploading) {
      return Scaffold(body: _buildProcessingAdOverlay());
    }

    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      appBar: AppBar(
        title: const Text('Nuevo Data Room'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KriptonTheme.alertRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: KriptonTheme.alertRed.withOpacity(0.3)),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: KriptonTheme.alertRed), textAlign: TextAlign.center),
              ).animate().shake(),
              const SizedBox(height: 16),
            ],
            if (!isComplete) ...[
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: _selectedFile == null ? KriptonTheme.inkDeep : KriptonTheme.ink,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _selectedFile == null ? KriptonTheme.cardBorder : KriptonTheme.electricLime.withOpacity(0.5)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_selectedFile == null ? Icons.cloud_upload_outlined : Icons.insert_drive_file, size: 40, color: _selectedFile == null ? KriptonTheme.silver : KriptonTheme.electricLime),
                      const SizedBox(height: 8),
                      Text(_selectedFile == null ? 'Toca para seleccionar archivo' : _selectedFile!.name, style: TextStyle(color: _selectedFile == null ? KriptonTheme.silver : KriptonTheme.platinum), textAlign: TextAlign.center),
                      if (_selectedFile != null && _selectedFileSize != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${(_selectedFileSize! / 1024).toStringAsFixed(1)} KB',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: KriptonTheme.silver),
                        ),
                      ],
                    ],
                  ),
                ),
              ).animate().fade(),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña de cifrado', hintText: 'No se almacena en la nube', prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _recipientController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email del receptor (opcional)', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 20),
              
              // INYECCIÓN DEL SLIDER DINÁMICO REFACTORIZADO
              _buildInteractiveDurationSlider(),
              
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _selectedFile == null ? null : _uploadAndEncrypt,
                child: const Text('Cifrar y generar enlace'),
              ),
            ],
            if (isComplete) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: KriptonTheme.ink, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, size: 64, color: KriptonTheme.cryptoGreen),
                    const SizedBox(height: 16),
                    Text('Data Room listo en Cloudflare', style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 20),
                    QrImageView(data: _shareLink!, version: QrVersions.auto, size: 140, backgroundColor: KriptonTheme.platinum),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: ElevatedButton(onPressed: () => _shareLinkToExternal(_shareLink!), child: const Text('Compartir'))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
