// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _controller.forward().then((_) => _resolveNextRoute());
  }

  Future<void> _resolveNextRoute() async {
    if (!mounted) return;

    // Esperar a que el provider de autenticación termine de inicializarse.
    var authValue = ref.read(authStateProvider);
    while (authValue is AsyncLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      authValue = ref.read(authStateProvider);
    }

    final session = authValue.valueOrNull;
    final isAuthenticated = session != null;

    if (!isAuthenticated) {
      context.go('/auth');
      return;
    }

    context.go('/dashboard');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: KriptonTheme.charcoalBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: KriptonTheme.brandGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: KriptonTheme.kryptonGreen.withOpacity(0.3),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'K',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 40,
                      color: KriptonTheme.platinum,
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(
                    duration: 800.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .fade(
                    duration: 400.ms,
                    delay: 200.ms,
                  ),
              const SizedBox(height: 32),
              Text(
                'KRIPTONSHARE',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      letterSpacing: -0.02,
                      fontSize: 24,
                    ),
              )
                  .animate()
                  .fade(delay: 600.ms, duration: 600.ms)
                  .slideY(
                    begin: 0.3,
                    end: 0,
                    delay: 600.ms,
                    duration: 600.ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 16),
              Text(
                'Data Room Efímero',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: KriptonTheme.silver,
                    ),
              )
                  .animate()
                  .fade(delay: 1000.ms, duration: 600.ms),
              const SizedBox(height: 48),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: KriptonTheme.electricLime,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    duration: 1200.ms,
                    curve: Curves.easeInOut,
                  )
                  .fade(
                    duration: 1200.ms,
                    curve: Curves.easeInOut,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
