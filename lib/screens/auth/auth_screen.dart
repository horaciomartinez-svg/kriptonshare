import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/language_selector_modal.dart';
import '../../providers/auth_provider.dart';
import '../../services/biometric_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final String? redirectPath;

  const AuthScreen({super.key, this.redirectPath});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateProvider.notifier).signIn(
        _loginEmailController.text.trim(),
        _loginPasswordController.text,
      );

      final currentState = ref.read(authStateProvider);
      if (mounted && currentState.hasError) {
        final error = currentState.error;
        setState(() {
          _errorMessage = error is Exception
              ? error.toString().replaceFirst('Exception: ', '')
              : AppLocalizations.of(context).loginInvalidCredentials;
        });
        return;
      }

      if (!mounted) return;

      // Si el desbloqueo biométrico está habilitado, pedirlo como segundo paso.
      final l10n = AppLocalizations.of(context);
      final biometricService = await BiometricService.create();
      final biometricEnabled = biometricService.isBiometricEnabled;
      final biometricAvailable = await biometricService.isBiometricAvailable();

      if (biometricEnabled && biometricAvailable) {
        final didAuthenticate = await biometricService.authenticate(
          localizedReason: l10n.biometricLoginReason,
        );
        if (!didAuthenticate) {
          // Si cancela la huella, cerramos la sesión recién iniciada para
          // evitar dejar la app desbloqueada.
          await ref.read(authStateProvider.notifier).signOut();
          if (mounted) {
            setState(() {
              _errorMessage = AppLocalizations.of(context).biometricAuthCancelled;
            });
          }
          return;
        }
      }

      if (!mounted) return;

      if (widget.redirectPath != null) {
        context.go(widget.redirectPath!);
      } else {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context).loginInvalidCredentials;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;

    if (_registerPasswordController.text != _registerConfirmController.text) {
      setState(() {
        _errorMessage = AppLocalizations.of(context).passwordsDoNotMatch;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateProvider.notifier).signUp(
        _registerEmailController.text.trim(),
        _registerPasswordController.text,
      );

      if (mounted && widget.redirectPath != null) {
        context.go(widget.redirectPath!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context).registerError;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.language, color: KriptonTheme.silver),
                  tooltip: l10n.selectLanguage,
                  onPressed: () => LanguageSelectorModal.show(context),
                ),
              ),
              const SizedBox(height: 16),
              // Logo
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: KriptonTheme.brandGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'K',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                        color: KriptonTheme.platinum,
                      ),
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.easeOutCubic)
                  .fade(),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  l10n.appName,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22),
                ),
              )
                  .animate()
                  .fade(delay: 200.ms)
                  .slideY(begin: 0.2, end: 0, delay: 200.ms),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  l10n.authTagline,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: KriptonTheme.silver,
                      ),
                ),
              )
                  .animate()
                  .fade(delay: 400.ms),
              const SizedBox(height: 32),
              
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KriptonTheme.alertRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: KriptonTheme.alertRed.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: KriptonTheme.alertRed,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
                    .animate()
                    .shake(),
              if (_errorMessage != null) const SizedBox(height: 16),
              
              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: KriptonTheme.inkDeep,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: KriptonTheme.electricLime.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorColor: KriptonTheme.electricLime,
                  labelColor: KriptonTheme.electricLime,
                  unselectedLabelColor: KriptonTheme.silver,
                  tabs: [
                    Tab(text: l10n.loginTab),
                    Tab(text: l10n.registerTab),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                height: 400,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Login Form
                    _buildLoginForm(),
                    // Register Form
                    _buildRegisterForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: KriptonTheme.platinum),
            decoration: InputDecoration(
              labelText: l10n.emailLabel,
              hintText: l10n.emailHint,
              prefixIcon: const Icon(Icons.email_outlined, color: KriptonTheme.silver),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return l10n.emailRequired;
              if (!value.contains('@')) return l10n.emailInvalid;
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: true,
            style: const TextStyle(color: KriptonTheme.platinum),
            decoration: InputDecoration(
              labelText: l10n.passwordLabel,
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline, color: KriptonTheme.silver),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return l10n.passwordRequired;
              if (value.length < 6) return l10n.passwordMinLength(6);
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _login,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(KriptonTheme.charcoalBlack),
                    ),
                  )
                : Text(l10n.loginButton),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.freePlanInfo(
              AppConstants.maxFileSizeBytes ~/ (1024 * 1024),
              AppConstants.maxLinksPerMonth,
              AppConstants.maxDurationHours,
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: KriptonTheme.graphite,
                  fontSize: 11,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _registerEmailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: KriptonTheme.platinum),
            decoration: InputDecoration(
              labelText: l10n.emailLabel,
              hintText: l10n.emailHint,
              prefixIcon: const Icon(Icons.email_outlined, color: KriptonTheme.silver),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return l10n.emailRequired;
              if (!value.contains('@')) return l10n.emailInvalid;
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerPasswordController,
            obscureText: true,
            style: const TextStyle(color: KriptonTheme.platinum),
            decoration: InputDecoration(
              labelText: l10n.passwordLabel,
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline, color: KriptonTheme.silver),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return l10n.passwordRequired;
              if (value.length < 8) return l10n.passwordMinLength(8);
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerConfirmController,
            obscureText: true,
            style: const TextStyle(color: KriptonTheme.platinum),
            decoration: InputDecoration(
              labelText: l10n.confirmPasswordLabel,
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline, color: KriptonTheme.silver),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return l10n.confirmPasswordRequired;
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _register,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(KriptonTheme.charcoalBlack),
                    ),
                  )
                : Text(l10n.registerButton),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.termsNotice,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: KriptonTheme.graphite,
                  fontSize: 11,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
