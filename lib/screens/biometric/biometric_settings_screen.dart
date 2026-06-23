import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import '../../core/utils/theme.dart';

/// Pantalla de configuración de biometría (huella / Face ID).
class BiometricSettingsScreen extends ConsumerStatefulWidget {
  const BiometricSettingsScreen({super.key});

  @override
  ConsumerState<BiometricSettingsScreen> createState() =>
      _BiometricSettingsScreenState();
}

class _BiometricSettingsScreenState
    extends ConsumerState<BiometricSettingsScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isLoading = true;
  bool _canCheckBiometrics = false;
  bool _isBiometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];
  String? _statusMessage;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final available = await _localAuth.getAvailableBiometrics();

      setState(() {
        _canCheckBiometrics = canCheck;
        _availableBiometrics = available;
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _canCheckBiometrics = false;
        _availableBiometrics = [];
        _isLoading = false;
        _statusMessage = 'Error al consultar biometría: ${e.message}';
        _statusIsError = true;
      });
    }
  }

  Future<void> _authenticate() async {
    if (!_canCheckBiometrics || _availableBiometrics.isEmpty) {
      _showStatus('No hay biometría disponible en este dispositivo.', isError: true);
      return;
    }

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Verifica tu identidad para acceder a KRIPTONSHARE',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        _showStatus('Autenticación biométrica exitosa.', isError: false);
      } else {
        _showStatus('Autenticación cancelada.', isError: true);
      }
    } on PlatformException catch (e) {
      String message;
      switch (e.code) {
        case auth_error.notAvailable:
          message = 'La biometría no está disponible.';
          break;
        case auth_error.notEnrolled:
          message = 'No hay biometría configurada en el dispositivo.';
          break;
        case auth_error.passcodeNotSet:
          message = 'No hay PIN/patrón configurado.';
          break;
        case auth_error.lockedOut:
          message = 'Demasiados intentos fallidos. Intenta más tarde.';
          break;
        default:
          message = 'Error de autenticación: ${e.message}';
      }
      _showStatus(message, isError: true);
    }
  }

  void _showStatus(String message, {required bool isError}) {
    setState(() {
      _statusMessage = message;
      _statusIsError = isError;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = null;
        });
      }
    });
  }

  void _toggleBiometric(bool value) {
    setState(() {
      _isBiometricEnabled = value;
    });

    _showStatus(
      value
          ? 'Desbloqueo biométrico activado para KRIPTONSHARE.'
          : 'Desbloqueo biométrico desactivado.',
      isError: false,
    );
  }

  IconData _biometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    }
    if (_availableBiometrics.contains(BiometricType.iris)) {
      return Icons.visibility;
    }
    return Icons.fingerprint;
  }

  String _biometricLabel() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    }
    if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    }
    return 'Huella digital';
  }

  String _biometricDescription() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Usa Face ID para desbloquear KRIPTONSHARE de forma segura.';
    }
    if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'Usa el reconocimiento de iris para acceder.';
    }
    return 'Usa tu huella digital para desbloquear la app rápidamente.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      appBar: AppBar(
        title: const Text('Biometría'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;
          final horizontalPadding = isTablet ? 48.0 : 20.0;
          final maxContentWidth = isTablet ? 800.0 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 24,
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(KriptonTheme.electricLime),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(theme)
                              .animate()
                              .fade(duration: 300.ms)
                              .slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 24),
                          if (isTablet)
                            _buildTabletLayout(theme)
                          else
                            _buildMobileLayout(theme),
                          const SizedBox(height: 24),
                          _buildStatusBanner(theme)
                              .animate()
                              .fade(delay: 300.ms, duration: 300.ms),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuración de Biometría',
          style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          'Protege el acceso a tus Data Rooms con tu identidad biométrica.',
          style: theme.textTheme.bodyMedium?.copyWith(
                color: KriptonTheme.silver,
              ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMainCard(theme)
            .animate()
            .fade(delay: 100.ms, duration: 300.ms)
            .slideY(begin: 0.1, end: 0),
        const SizedBox(height: 16),
        _buildSecurityInfoCard(theme)
            .animate()
            .fade(delay: 200.ms, duration: 300.ms)
            .slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildTabletLayout(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildMainCard(theme)
              .animate()
              .fade(delay: 100.ms, duration: 300.ms)
              .slideY(begin: 0.1, end: 0),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSecurityInfoCard(theme)
              .animate()
              .fade(delay: 200.ms, duration: 300.ms)
              .slideY(begin: 0.1, end: 0),
        ),
      ],
    );
  }

  Widget _buildMainCard(ThemeData theme) {
    final biometricIcon = _biometricIcon();
    final biometricLabel = _biometricLabel();
    final biometricDescription = _biometricDescription();
    final hasBiometrics =
        _canCheckBiometrics && _availableBiometrics.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KriptonTheme.ink,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: KriptonTheme.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: KriptonTheme.brandGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [KriptonTheme.kryptonGlow],
            ),
            child: Icon(
              biometricIcon,
              size: 48,
              color: KriptonTheme.platinum,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hasBiometrics ? biometricLabel : 'Biometría no disponible',
            style: theme.textTheme.displayMedium?.copyWith(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasBiometrics
                ? biometricDescription
                : 'Este dispositivo no tiene sensores biométricos configurados.',
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: KriptonTheme.silver,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (hasBiometrics) ...[
            _buildToggleRow(theme),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.security),
              label: const Text('Probar ahora'),
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: _checkBiometrics,
              icon: const Icon(Icons.refresh),
              label: const Text('Verificar de nuevo'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleRow(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KriptonTheme.inkDeep,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isBiometricEnabled
                  ? KriptonTheme.electricLime.withOpacity(0.15)
                  : KriptonTheme.alertRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isBiometricEnabled ? Icons.lock_open : Icons.lock_outline,
              color: _isBiometricEnabled
                  ? KriptonTheme.electricLime
                  : KriptonTheme.alertRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Desbloqueo biométrico',
                  style: theme.textTheme.bodyMedium?.copyWith(
                        color: KriptonTheme.platinum,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  _isBiometricEnabled ? 'Activado' : 'Desactivado',
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: KriptonTheme.silver,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isBiometricEnabled,
            onChanged: _toggleBiometric,
            activeColor: KriptonTheme.electricLime,
            activeTrackColor: KriptonTheme.electricLime.withOpacity(0.3),
            inactiveThumbColor: KriptonTheme.platinum,
            inactiveTrackColor: KriptonTheme.cardBorder,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfoCard(ThemeData theme) {
    final items = [
      _SecurityInfoItem(
        icon: Icons.verified_user,
        title: 'Soberanía de datos',
        description:
            'Tu huella o rostro nunca salen del dispositivo. No almacenamos datos biométricos.',
      ),
      _SecurityInfoItem(
        icon: Icons.speed,
        title: 'Acceso rápido',
        description:
            'Desbloquea KRIPTONSHARE sin escribir tu contraseña cada vez.',
      ),
      _SecurityInfoItem(
        icon: Icons.shield_outlined,
        title: 'Protección adicional',
        description:
            'La biometría complementa tu contraseña; no la reemplaza.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KriptonTheme.ink,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: KriptonTheme.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seguridad',
            style: theme.textTheme.displayMedium?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: KriptonTheme.electricLime.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.icon,
                      color: KriptonTheme.electricLime,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: KriptonTheme.platinum,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: KriptonTheme.silver,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(ThemeData theme) {
    if (_statusMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _statusIsError
            ? KriptonTheme.alertRed.withOpacity(0.1)
            : KriptonTheme.cryptoGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _statusIsError
              ? KriptonTheme.alertRed.withOpacity(0.3)
              : KriptonTheme.cryptoGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _statusIsError ? Icons.error_outline : Icons.check_circle_outline,
            color: _statusIsError
                ? KriptonTheme.alertRed
                : KriptonTheme.cryptoGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: _statusIsError
                        ? KriptonTheme.alertRed
                        : KriptonTheme.cryptoGreen,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityInfoItem {
  final IconData icon;
  final String title;
  final String description;

  _SecurityInfoItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
