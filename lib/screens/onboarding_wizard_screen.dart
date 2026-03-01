import 'package:flutter/material.dart';
import 'package:friendsride_app/theme/app_colors.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';

/// Wizard de onboarding multi-pas
class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _getStarted() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildPage1Welcome(),
                  _buildPage2HowItWorks(),
                  _buildPage3Features(),
                  _buildPage4GetStarted(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: _prevPage,
              child: const Text('Înapoi'),
            )
          else
            const SizedBox(width: 80),
          _buildDotIndicators(),
          if (_currentPage < _totalPages - 1)
            TextButton(
              onPressed: _skip,
              child: const Text('Sari peste'),
            )
          else
            const SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildDotIndicators() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_totalPages, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.textDisabled,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: _currentPage < _totalPages - 1
          ? ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Continuă', style: AppTextStyles.buttonLarge),
            )
          : const SizedBox.shrink(),
    );
  }

  // ---- Page 1: Welcome ----
  Widget _buildPage1Welcome() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Bun venit la\nFriendsRide!',
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Cursele tale, pe bune prietenie.\nRapid, sigur și accesibil în toată România.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ---- Page 2: How it works ----
  Widget _buildPage2HowItWorks() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Cum funcționează?',
            style: AppTextStyles.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildStep(
            icon: Icons.location_on_rounded,
            color: AppColors.primary,
            title: 'Setează destinația',
            description: 'Introdu adresa de destinație și vei vedea estimarea prețului.',
          ),
          const SizedBox(height: 24),
          _buildStep(
            icon: Icons.directions_car_filled,
            color: AppColors.secondary,
            title: 'Alege mașina',
            description: 'Selectează tipul de vehicul potrivit pentru tine.',
          ),
          const SizedBox(height: 24),
          _buildStep(
            icon: Icons.star_rounded,
            color: AppColors.accent,
            title: 'Bucură-te de cursă',
            description: 'Șoferul ajunge în câteva minute. Plata se face simplu!',
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headingSmall),
              const SizedBox(height: 4),
              Text(description,
                  style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Page 3: Features ----
  Widget _buildPage3Features() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'De ce FriendsRide?',
            style: AppTextStyles.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildFeatureTile(
            icon: Icons.security_rounded,
            title: 'Siguranță maximă',
            description: 'Toți șoferii sunt verificați și evaluați de comunitate.',
          ),
          _buildFeatureTile(
            icon: Icons.group_rounded,
            title: 'Curse partajate',
            description: 'Împarte costul cursei cu alți pasageri pe același drum.',
          ),
          _buildFeatureTile(
            icon: Icons.card_giftcard,
            title: 'Cadouri și recompense',
            description: 'Trimite curse cadou sau câștigă din programul de referral.',
          ),
          _buildFeatureTile(
            icon: Icons.schedule_rounded,
            title: 'Curse programate',
            description: 'Planifică cursele cu anticipație, fără griji.',
          ),
          _buildFeatureTile(
            icon: Icons.star_rounded,
            title: 'Program de loialitate',
            description: 'Colectează puncte la fiecare cursă și câștigă beneficii.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                Text(description, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Page 4: Get Started ----
  Widget _buildPage4GetStarted() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.secondaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              size: 52,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Ești pregătit?',
            style: AppTextStyles.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Conectează-te sau continuă ca vizitator\npentru a solicita prima ta cursă!',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _getStarted,
            icon: const Icon(Icons.login_rounded),
            label: const Text('Conectare / Înregistrare'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: AppTextStyles.buttonLarge,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
            icon: const Icon(Icons.person_outline),
            label: const Text('Continuă ca vizitator'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 52),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: AppTextStyles.buttonLarge
                  .copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
