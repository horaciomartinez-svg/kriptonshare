// lib/features/upload/presentation/screens/upload_screen.dart
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart' show lookupMimeType;
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/localization/formatters.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/file_provider.dart';
import '../../../../utils/supported_formats.dart';
import '../../../../utils/theme.dart';
import '../../../../utils/constants.dart';
import '../../../../models/user_model.dart';
import '../../../../features/subscription/presentation/widgets/paywall_sheet.dart';
import '../widgets/unsupported_format_dialog.dart';

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
  String _processingStep = 'encrypting';
  String? _shareLink;
  String? _errorMessage;
  double _progress = 0;

  bool _durationPaywallShown = false;

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

  String _mimeOf(XFile file) =>
      file.mimeType ??
      lookupMimeType(file.name) ??
      'application/octet-stream';

  Future<void> _pickFile() async {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authStateProvider).valueOrNull;

    try {
      final file = await openFile();
      if (file == null || !mounted) return;

      // Bloqueo de formatos en origen (§3.4): solo se aceptan formatos
      // visualizables de forma segura dentro de la app.
      if (!SupportedFormats.isViewable(
        mimeType: _mimeOf(file),
        fileName: file.name,
      )) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const UnsupportedFormatDialog(),
        );
        return;
      }

      final length = await file.length();
      if (!mounted) return;
      final int maxLimit = user?.maxFileSizeBytes ?? AppConstants.freeMaxFileSizeBytes;
      if (length > maxLimit) {
        await _rejectFileTooLarge(formatBytes(context, maxLimit));
        return;
      }

      setState(() {
        _selectedFile = file;
        _selectedFileSize = length;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = l10n.filePickError);
    }
  }

  // FEATURE CRÍTICO DEL MVP: CÁMARA DIRECTA A BÓVEDA SIN TRANSITAR POR GALERÍA PÚBLICA
  Future<void> _captureSecurePhoto() async {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authStateProvider).valueOrNull;
    final int maxLimit = user?.maxFileSizeBytes ?? AppConstants.freeMaxFileSizeBytes;
    final String maxSize = formatBytes(context, maxLimit);

    try {
      final XFile? photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (photo != null) {
        final length = await photo.length();
        if (length > maxLimit) {
          await _rejectFileTooLarge(maxSize);
          return;
        }
        setState(() {
          _selectedFile = photo;
          _selectedFileSize = length;
          _errorMessage = null;
        });
      }
    } catch (_) {
      setState(() => _errorMessage = l10n.cameraAccessCancelled);
    }
  }

  /// Paywall contextual `fileSizeLimit` para usuarios free; los planes de pago
  /// (o el tope del propio plan) muestran solo un error plano (§10.2).
  Future<void> _rejectFileTooLarge(String maxSize) async {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authStateProvider).valueOrNull;

    setState(() {
      _selectedFile = null;
      _selectedFileSize = null;
      _errorMessage = l10n.fileExceedsPlanLimit(maxSize);
    });

    if (user != null && user.isFree) {
      await PaywallSheet.show(context, trigger: 'file_size');
    }
  }

  /// Muestra paywall contextual según el motivo de rechazo de `canUpload()`,
  /// o un error plano para usuarios de pago / motivos no comerciales (§10.2).
  Future<void> _handleQuotaRejection(String? reasonCode, String? message) async {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authStateProvider).valueOrNull;
    final isBusiness = user?.effectiveTier == 'business';

    final bool canSell = user != null &&
        user.isFree &&
        !isBusiness &&
        reasonCode != null &&
        reasonCode != 'general';

    if (!canSell) {
      setState(() {
        _errorMessage = message ?? l10n.errorQuotaExceeded;
      });
      return;
    }

    await PaywallSheet.show(context, trigger: reasonCode);
  }

  Future<void> _uploadAndEncrypt() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedFile == null) return;
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = l10n.enterEncryptionPassword);
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      setState(() => _errorMessage = l10n.sessionExpired);
      return;
    }

    final fileBytes = await _selectedFile!.readAsBytes();

    // Validación de cuotas autoritativa (RPC `check_upload_limits` con reason_code).
    final fileService = ref.read(fileServiceProvider);
    final limitResult = await fileService.canUpload(fileBytes.length, user.id);
    if (!limitResult.allowed) {
      await _handleQuotaRejection(limitResult.reasonCode, limitResult.message);
      return;
    }

    setState(() {
      _isEncrypting = true;
      _isUploading = false;
      _processingStep = 'encrypting';
      _errorMessage = null;
      _progress = 0.2;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    try {
      final mimeType = _mimeOf(_selectedFile!);

      final link = await fileService.uploadAndCreateLink(
        fileBytes: fileBytes,
        fileName: _selectedFile!.name,
        mimeType: mimeType,
        userPassword: _passwordController.text,
        selectedDurationHours: _selectedDurationHours.toInt(),
        recipientEmail: _recipientController.text.isEmpty ? null : _recipientController.text,
        onProgress: (status) {
          if (!mounted) return;
          setState(() {
            _isEncrypting = status == 'encrypting';
            _isUploading = status == 'syncing';
            _processingStep = status;
            _progress = status == 'encrypting' ? 0.35 : 0.75;
          });
        },
      );

      setState(() {
        _progress = 1.0;
        _isUploading = false;
        _isEncrypting = false;
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

  // FEATURE CRÍTICO DEL MVP: SHARE SHEET NATIVO UNIFICADO MULTIPLATAFORMA
  void _shareLinkToExternal(String url) {
    final l10n = AppLocalizations.of(context);
    ref.invalidate(userLinksProvider);
    Share.share(
      l10n.shareMessageTemplate(
        url,
        AppConstants.appLinkUrl(url),
        _selectedDurationHours.toInt(),
      ),
      subject: l10n.shareDataRoomTitle,
    );
  }

  // === COMPONENTE COMPACTO DEL SLIDER INTERACTIVO (ADAPTATIVO POR TIER) ===
  Widget _buildInteractiveDurationSlider(KriptonUser user) {
    final l10n = AppLocalizations.of(context);
    final bool isPremium = user.isPremium;
    final double maxRange = user.maxDurationHours.toDouble(); // free 168h · premium/trial 720h · business 1440h

    String formattedDurationLabel(double hours) {
      final rounded = hours.round();
      if (rounded >= 24) {
        return l10n.daysUnit(rounded ~/ 24);
      }
      return l10n.hoursUnit(rounded);
    }

    String sliderThumbLabel(double hours) {
      final rounded = hours.round();
      if (rounded >= 24) {
        return '${rounded ~/ 24}d';
      }
      return '${rounded}h';
    }

    final String maxLabel = switch (user.effectiveTier) {
      'business' => l10n.max60Days,
      'premium' => l10n.max30Days,
      _ => l10n.max7Days,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KriptonTheme.inkDeep,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius.toDouble()),
        border: Border.all(color: isPremium ? KriptonTheme.electricLime.withOpacity(0.3) : KriptonTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(l10n.expirationLabel, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
                  if (isPremium) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: KriptonTheme.electricLime.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.effectiveTier == 'business'
                            ? l10n.businessBadge
                            : l10n.premiumBadge,
                        style: const TextStyle(color: KriptonTheme.electricLime, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: KriptonTheme.charcoalBlack,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: KriptonTheme.electricLime.withOpacity(0.5)),
                ),
                child: Text(
                  formattedDurationLabel(_selectedDurationHours),
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
              value: _selectedDurationHours.clamp(1.0, maxRange),
              min: 1.0,
              max: maxRange,
              label: sliderThumbLabel(_selectedDurationHours),
              onChanged: (_isEncrypting || _isUploading)
                  ? null
                  : (value) {
                      final snapped = value.round().clamp(1, maxRange.round()).toDouble();
                      setState(() => _selectedDurationHours = snapped);

                      // Usuario free: tope en 168 h y paywall suave la primera
                      // vez que alcanza el máximo por sesión (§10.2 durationLimit).
                      if (!user.isPremium &&
                          snapped >= maxRange &&
                          !_durationPaywallShown) {
                        _durationPaywallShown = true;
                        PaywallSheet.show(context, trigger: 'link_duration');
                      }
                    },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.oneHour, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: KriptonTheme.graphite)),
              Text(maxLabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: KriptonTheme.graphite, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // === VISTA DE PROCESAMIENTO (sin publicidad) ===
  Widget _buildProcessingView() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: KriptonTheme.electricLime)
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1200.ms),
              const SizedBox(height: 12),
              Text(
                l10n.protectingFiles,
                style: const TextStyle(
                  color: KriptonTheme.platinum,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: KriptonTheme.inkDeep,
                valueColor: const AlwaysStoppedAnimation(KriptonTheme.electricLime),
              ),
              const SizedBox(height: 10),
              Text(
                _processingStep == 'encrypting'
                    ? l10n.encryptingAesStep
                    : l10n.syncingR2Step,
                style: const TextStyle(
                  color: KriptonTheme.cyanTelemetry,
                  fontFamily: 'SFMono',
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isComplete = _shareLink != null;
    final user = ref.watch(authStateProvider).valueOrNull;

    if (_isEncrypting || _isUploading) {
      return _buildProcessingView();
    }

    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      appBar: AppBar(
        title: Text(l10n.newDataRoom),
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
              // PANEL DUAL: SELECCIONAR ARCHIVO O CAPTURAR DESDE CÁMARA VAULT
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
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
                            Icon(_selectedFile == null ? Icons.cloud_upload_outlined : Icons.insert_drive_file, size: 32, color: _selectedFile == null ? KriptonTheme.silver : KriptonTheme.electricLime),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                _selectedFile == null ? l10n.attachFile : _selectedFile!.name,
                                style: TextStyle(color: _selectedFile == null ? KriptonTheme.silver : KriptonTheme.platinum, fontSize: 12),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_selectedFile != null && _selectedFileSize != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                formatBytes(context, _selectedFileSize!),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: KriptonTheme.silver, fontSize: 10),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _captureSecurePhoto,
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: KriptonTheme.inkDeep,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: KriptonTheme.cardBorder),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.photo_camera_outlined, size: 32, color: KriptonTheme.silver),
                            const SizedBox(height: 8),
                            Text(l10n.cameraToVault, style: const TextStyle(color: KriptonTheme.platinum, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(l10n.noPublicGallery, style: const TextStyle(color: KriptonTheme.graphite, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fade(),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.encryptionPasswordLabel, hintText: l10n.passwordNotStoredHint, prefixIcon: const Icon(Icons.lock)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _recipientController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.recipientEmailOptional, prefixIcon: const Icon(Icons.person)),
              ),
              const SizedBox(height: 20),

              // INYECCIÓN DEL SLIDER DINÁMICO REFACTORIZADO
              if (user != null) _buildInteractiveDurationSlider(user),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _selectedFile == null ? null : _uploadAndEncrypt,
                child: Text(l10n.encryptAndGenerateLink),
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
                    Text(l10n.dataRoomReadyBanner, style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 20),
                    QrImageView(data: _shareLink!, version: QrVersions.auto, size: 140, backgroundColor: KriptonTheme.platinum),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: ElevatedButton(onPressed: () => _shareLinkToExternal(_shareLink!), child: Text(l10n.share))),
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
