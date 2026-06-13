import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) context.go('/auth');
      });
    });
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
              // Logo cristalino K
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
                  .animate(controller: _controller)
                  .scale(
                    duration: 800.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .fade(
                    duration: 400.ms,
                    delay: 200.ms,
                  ),
              const SizedBox(height: 32),
              // Wordmark
              Text(
                'KRIPTONSHARE',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      letterSpacing: -0.02,
                      fontSize: 24,
                    ),
              )
                  .animate(controller: _controller)
                  .fade(delay: 600.ms, duration: 600.ms)
                  .slideY(
                    begin: 0.3,
                    end: 0,
                    delay: 600.ms,
                    duration: 600.ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 16),
              // Tagline
              Text(
                'Data Room Efímero',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: KriptonTheme.silver,
                    ),
              )
                  .animate(controller: _controller)
                  .fade(delay: 1000.ms, duration: 600.ms),
              const SizedBox(height: 48),
              // Pulse indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: KriptonTheme.electricLime,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
                  .animate(controller: _controller, onPlay: (c) => c.repeat())
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
