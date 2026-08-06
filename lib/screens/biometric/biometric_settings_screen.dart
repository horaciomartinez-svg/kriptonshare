import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/theme.dart';
import '../../services/biometric_service.dart';

/// Pantalla de configuración de biometría (huella / Face ID).
class BiometricSettingsScreen extends ConsumerStatefulWidget {
  const BiometricSettingsScreen({super.key});

  @override
  ConsumerState<BiometricSettingsScreen> createState() =>
      _BiometricSettingsScreenState();
}

class _BiometricSettingsScreenState
    extends ConsumerState<BiometricSettingsScreen> {
  BiometricService? _biometricService;

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
    _biometricService = await BiometricService.create();
    _isBiometricEnabled = _biometricService?.isBiometricEnabled ?? false;
    await _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    if (_biometricService == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final canCheck = await _biometricService!.canCheckBiometrics();
      final available = await _biometricService!.getAvailableBiometrics();

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
        _statusMessage = AppLocalizations.of(context).biometricQueryError(e.message ?? '');
        _statusIsError = true;
      });
    }
  }

  Future<void> _authenticate() async {
    if (_biometricService == null) return;
    final l10n = AppLocalizations.of(context);
    if (!_canCheckBiometrics || _availableBiometrics.isEmpty) {
      _showStatus(l10n.biometricNotAvailableTitle, isError: true);
      return;
    }

    try {
      final didAuthenticate = await _biometricService!.authenticate();

      if (didAuthenticate) {
        _showStatus(l10n.biometricAuthSuccess, isError: false);
      } else {
        _showStatus(l10n.authCancelled, isError: true);
      }
    } catch (e) {
      _showStatus(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _showStatus(String message, {required bool isError}) {
    if (!mounted) return;
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

  Future<void> _toggleBiometric(bool value) async {
    if (_biometricService == null) return;
    final l10n = AppLocalizations.of(context);

    if (value) {
      // Antes de activar el desbloqueo biométrico, exige una autenticación
      // exitosa para confirmar que el usuario controla el dispositivo.
      if (!_canCheckBiometrics || _availableBiometrics.isEmpty) {
        _showStatus(l10n.biometricNotAvailableTitle, isError: true);
        return;
      }

      try {
        final didAuthenticate = await _biometricService!.authenticate(
          localizedReason: l10n.biometricEnableReason,
        );

        if (!didAuthenticate) {
          _showStatus(l10n.biometricEnableCancelled, isError: true);
          return;
        }

        await _biometricService!.setBiometricEnabled(true);
        setState(() => _isBiometricEnabled = true);
        _showStatus(l10n.biometricUnlockEnabledMsg, isError: false);
      } catch (e) {
        _showStatus(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } else {
      await _biometricService!.setBiometricEnabled(false);
      setState(() => _isBiometricEnabled = false);
      _showStatus(l10n.biometricUnlockDisabledMsg, isError: false);
    }
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

  String _biometricLabel(AppLocalizations l10n) {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return l10n.faceId;
    }
    if (_availableBiometrics.contains(BiometricType.iris)) {
      return l10n.iris;
    }
    return l10n.fingerprint;
  }

  String _biometricDescription(AppLocalizations l10n) {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return l10n.faceIdDescription;
    }
    if (_availableBiometrics.contains(BiometricType.iris)) {
      return l10n.irisDescription;
    }
    return l10n.fingerprintDescription;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      appBar: AppBar(
        title: Text(l10n.biometricSettingsTitle),
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
                          _buildHeader(theme, l10n)
                              .animate()
                              .fade(duration: 300.ms)
                              .slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 24),
                          if (isTablet)
                            _buildTabletLayout(theme, l10n)
                          else
                            _buildMobileLayout(theme, l10n),
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

  Widget _buildHeader(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.biometricSettingsTitle,
          style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.biometricIntro,
          style: theme.textTheme.bodyMedium?.copyWith(
                color: KriptonTheme.silver,
              ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMainCard(theme, l10n)
            .animate()
            .fade(delay: 100.ms, duration: 300.ms)
            .slideY(begin: 0.1, end: 0),
        const SizedBox(height: 16),
        _buildSecurityInfoCard(theme, l10n)
            .animate()
            .fade(delay: 200.ms, duration: 300.ms)
            .slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildTabletLayout(ThemeData theme, AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildMainCard(theme, l10n)
              .animate()
              .fade(delay: 100.ms, duration: 300.ms)
              .slideY(begin: 0.1, end: 0),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSecurityInfoCard(theme, l10n)
              .animate()
              .fade(delay: 200.ms, duration: 300.ms)
              .slideY(begin: 0.1, end: 0),
        ),
      ],
    );
  }

  Widget _buildMainCard(ThemeData theme, AppLocalizations l10n) {
    final biometricIcon = _biometricIcon();
    final biometricLabel = _biometricLabel(l10n);
    final biometricDescription = _biometricDescription(l10n);
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
            hasBiometrics ? biometricLabel : l10n.biometricNotAvailableTitle,
            style: theme.textTheme.displayMedium?.copyWith(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasBiometrics
                ? biometricDescription
                : l10n.biometricNoSensorsBody,
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: KriptonTheme.silver,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (hasBiometrics) ...[
            _buildToggleRow(theme, l10n),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.security),
              label: Text(l10n.testNow),
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: _checkBiometrics,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.verifyAgain),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleRow(ThemeData theme, AppLocalizations l10n) {
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
                  l10n.biometricUnlock,
                  style: theme.textTheme.bodyMedium?.copyWith(
                        color: KriptonTheme.platinum,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  _isBiometricEnabled ? l10n.enabled : l10n.disabled,
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

  Widget _buildSecurityInfoCard(ThemeData theme, AppLocalizations l10n) {
    final items = [
      _SecurityInfoItem(
        icon: Icons.verified_user,
        title: l10n.dataSovereigntyTitle,
        description: l10n.dataSovereigntyBody,
      ),
      _SecurityInfoItem(
        icon: Icons.speed,
        title: l10n.quickAccessTitle,
        description: l10n.quickAccessBody,
      ),
      _SecurityInfoItem(
        icon: Icons.shield_outlined,
        title: l10n.extraProtectionTitle,
        description: l10n.extraProtectionBody,
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
            l10n.securityTitle,
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
