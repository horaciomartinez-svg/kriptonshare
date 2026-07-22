import 'package:flutter/material.dart';
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

  final List<Map<String, String>> _slides = [
    {
      'title': 'Cifrado Zero-Knowledge',
      'body': 'Tus archivos se encriptan localmente con AES-256 antes de subir a la nube. Nadie más que tú posee el control de las llaves.',
    },
    {
      'title': 'Enlaces Efímeros',
      'body': 'Configura la autodestrucción física de tus documentos. Elige la duración exacta de validez del link de acceso seguro.',
    },
    {
      'title': 'Seguridad Forense',
      'body': 'Mitiga el espionaje corporativo y las filtraciones físicas con marcas de agua dinámicas y bloqueo de capturas de pantalla.',
    },
  ];

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
                  itemCount: _slides.length,
                  itemBuilder: (context, index) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined, size: 80, color: KriptonTheme.electricLime),
                      const SizedBox(height: 32),
                      Text(
                        _slides[index]['title']!,
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _slides[index]['body']!,
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
                    child: const Text('OMITIR', style: TextStyle(color: KriptonTheme.graphite)),
                  ),
                  Row(
                    children: List.generate(
                      _slides.length,
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
                      if (_currentPage == _slides.length - 1) {
                        _finishOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                      _currentPage == _slides.length - 1 ? 'EMPEZAR' : 'SIGUIENTE',
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
