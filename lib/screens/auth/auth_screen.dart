import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

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
    } catch (e) {
      setState(() {
        _errorMessage = 'Credenciales inválidas. Intenta de nuevo.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;
    
    if (_registerPasswordController.text != _registerConfirmController.text) {
      setState(() {
        _errorMessage = 'Las contraseñas no coinciden';
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
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al crear cuenta. Intenta con otro email.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
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
                  'KRIPTONSHARE',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22),
                ),
              )
                  .animate()
                  .fade(delay: 200.ms)
                  .slideY(begin: 0.2, end: 0, delay: 200.ms),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tu dispositivo es el único custodio',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: KriptonTheme.silver,
                      ),
                ),
              )
                  .animate()
                  .fade(delay: 400.ms),
              const SizedBox(height: 48),
              
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
                  tabs: const [
                    Tab(text: 'Iniciar sesión'),
                    Tab(text: 'Crear cuenta'),
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
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: KriptonTheme.platinum),
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'tu@email.com',
              prefixIcon: Icon(Icons.email_outlined, color: KriptonTheme.silver),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email requerido';
              if (!value.contains('@')) return 'Email inválido';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: true,
            style: const TextStyle(color: KriptonTheme.platinum),
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              hintText: '••••••••',
              prefixIcon: Icon(Icons.lock_outline, color: KriptonTheme.silver),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Contraseña requerida';
              if (value.length < 6) return 'Mínimo 6 caracteres';
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
                : const Text('Iniciar sesión'),
          ),
          const SizedBox(height: 16),
          Text(
            'Plan gratuito: 10 MB máximo · 50 links/mes · 72h de duración',
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
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _registerEmailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: KriptonTheme.platinum),
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'tu@email.com',
              prefixIcon: Icon(Icons.email_outlined, color: KriptonTheme.silver),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email requerido';
              if (!value.contains('@')) return 'Email inválido';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerPasswordController,
            obscureText: true,
            style: const TextStyle(color: KriptonTheme.platinum),
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              hintText: '••••••••',
              prefixIcon: Icon(Icons.lock_outline, color: KriptonTheme.silver),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Contraseña requerida';
              if (value.length < 8) return 'Mínimo 8 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerConfirmController,
            obscureText: true,
            style: const TextStyle(color: KriptonTheme.platinum),
            decoration: const InputDecoration(
              labelText: 'Confirmar contraseña',
              hintText: '••••••••',
              prefixIcon: Icon(Icons.lock_outline, color: KriptonTheme.silver),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Confirmación requerida';
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
                : const Text('Crear cuenta gratis'),
          ),
          const SizedBox(height: 16),
          Text(
            'Al registrarte, aceptas los términos de soberanía de datos. KRIPTONSHARE nunca almacena tus archivos en texto plano.',
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
