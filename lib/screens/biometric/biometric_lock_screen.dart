import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/biometric_service.dart';
import '../../utils/theme.dart';

/// Pantalla de bloqueo biométrico.
///
/// Se muestra al iniciar la app cuando el usuario tiene una sesión activa
/// y habilitó previamente el desbloqueo biométrico. Actúa como una
/// segunda capa de protección local antes de entrar al dashboard.
class BiometricLockScreen extends ConsumerStatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  ConsumerState<BiometricLockScreen> createState() =>
      _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Intenta autenticar automáticamente apenas se construye la pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final service = await BiometricService.create();
      final didAuthenticate = await service.authenticate();

      if (!mounted) return;

      if (!didAuthenticate) {
        setState(() {
          _errorMessage = 'Autenticación cancelada.';
        });
        return;
      }

      // Recuperar credenciales guardadas y hacer login automático en Supabase.
      final credentials = await SecureCredentialService.getCredentials();

      if (credentials == null) {
        // Si no hay credenciales, la biometría no puede sustituir el login.
        await service.setBiometricEnabled(false);
        if (mounted) {
          _showStatusAndRedirect(
            'No hay credenciales guardadas. Inicia sesión manualmente.',
            '/auth',
          );
        }
        return;
      }

      await ref.read(authStateProvider.notifier).signIn(
            credentials['email']!,
            credentials['password']!,
          );

      final currentState = ref.read(authStateProvider);
      if (!mounted) return;

      if (currentState.hasError || currentState.valueOrNull == null) {
        _showStatusAndRedirect(
          'Las credenciales guardadas ya no son válidas. Inicia sesión manualmente.',
          '/auth',
        );
        return;
      }

      context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  void _showStatusAndRedirect(String message, String route) {
    setState(() => _errorMessage = message);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go(route);
    });
  }

  Future<void> _signOut() async {
    await ref.read(authStateProvider.notifier).signOut();
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: KriptonTheme.brandGradient,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [KriptonTheme.kryptonGlow],
                ),
                child: const Icon(
                  Icons.fingerprint,
                  size: 64,
                  color: KriptonTheme.platinum,
                ),
              )
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.easeOutCubic)
                  .fade(),
              const SizedBox(height: 40),
              Text(
                'KRIPTONSHARE bloqueado',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 24,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Usa tu huella o rostro para desbloquear la app.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: KriptonTheme.silver,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KriptonTheme.alertRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: KriptonTheme.alertRed.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: KriptonTheme.alertRed),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: KriptonTheme.alertRed),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              ElevatedButton.icon(
                onPressed: _isAuthenticating ? null : _authenticate,
                icon: _isAuthenticating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                              KriptonTheme.charcoalBlack),
                        ),
                      )
                    : const Icon(Icons.fingerprint),
                label: Text(_isAuthenticating
                    ? 'Verificando...'
                    : 'Desbloquear con biometría'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _signOut,
                child: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: KriptonTheme.silver),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
