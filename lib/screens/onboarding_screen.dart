import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) context.go('/dashboard');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slides = [
      _OnboardingSlide(l10n.onboardingTitle1, l10n.onboardingBody1),
      _OnboardingSlide(l10n.onboardingTitle2, l10n.onboardingBody2),
      _OnboardingSlide(l10n.onboardingTitle3, l10n.onboardingBody3),
    ];

    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: slides.length,
                  itemBuilder: (context, index) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined, size: 80, color: KriptonTheme.electricLime),
                      const SizedBox(height: 32),
                      Text(
                        slides[index].title,
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        slides[index].body,
                        style: const TextStyle(color: KriptonTheme.silver, fontSize: 14, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: Text(l10n.onboardingSkip, style: const TextStyle(color: KriptonTheme.graphite)),
                  ),
                  Row(
                    children: List.generate(
                      slides.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index ? KriptonTheme.electricLime : KriptonTheme.cardBorder,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_currentPage == slides.length - 1) {
                        _finishOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                      _currentPage == slides.length - 1 ? l10n.onboardingStart : l10n.onboardingNext,
                      style: const TextStyle(color: KriptonTheme.electricLime),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final String title;
  final String body;

  const _OnboardingSlide(this.title, this.body);
}
