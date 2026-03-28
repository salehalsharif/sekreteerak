import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

/// Onboarding screen with 3 slides + permissions
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.record_voice_over_rounded,
      title: 'تكلم بطبيعتك',
      subtitle: 'سجّل مهامك ومواعيدك بصوتك\nكأنك تتكلم مع سكرتيرك الشخصي',
      gradient: AppTheme.primaryGradient,
    ),
    _OnboardingPage(
      icon: Icons.auto_awesome_rounded,
      title: 'نفهم ونرتب',
      subtitle: 'نحوّل كلامك إلى مهام منظمة\nبالتاريخ والوقت والأولوية',
      gradient: AppTheme.accentGradient,
    ),
    _OnboardingPage(
      icon: Icons.notifications_active_rounded,
      title: 'نتابع عنك',
      subtitle: 'نذكّرك قبل الموعد ونتابع\nالمهام المتأخرة بذكاء',
      gradient: AppTheme.warmGradient,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    _currentPage < 2 ? 'تخطّي' : '',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: _pages,
              ),
            ),

            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: AppTheme.animNormal,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? AppTheme.primaryColor
                        : AppTheme.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // CTA button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: AppTheme.animNormal,
                        curve: Curves.easeInOut,
                      );
                    } else {
                      context.go('/home');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'التالي' : 'ابدأ الآن',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with gradient
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 56,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 40),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
              height: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
