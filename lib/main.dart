import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:friendsride_app/l10n/app_localizations.dart';
import 'package:friendsride_app/theme/app_colors.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';
import 'package:friendsride_app/screens/onboarding_wizard_screen.dart';
import 'package:friendsride_app/screens/social_login_screen.dart';
import 'package:friendsride_app/screens/ride_preferences_screen.dart';
import 'package:friendsride_app/screens/referral_screen.dart';
import 'package:friendsride_app/screens/gift_ride_screen.dart';
import 'package:friendsride_app/screens/scheduled_ride_notifications_screen.dart';
import 'package:friendsride_app/screens/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isFirstTime = prefs.getBool('onboarding_completed') != true;
  runApp(FriendsRideApp(isFirstTime: isFirstTime));
}

class FriendsRideApp extends StatelessWidget {
  final bool isFirstTime;

  const FriendsRideApp({super.key, this.isFirstTime = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FriendsRide',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: isFirstTime ? '/onboarding' : '/home',
      routes: {
        '/onboarding': (_) => const _OnboardingWrapper(),
        '/login': (_) => const SocialLoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/ride-preferences': (_) => const RidePreferencesScreen(),
        '/referral': (_) => const ReferralScreen(),
        '/gift-ride': (_) => const GiftRideScreen(),
        '/scheduled-rides': (_) => const ScheduledRideNotificationsScreen(),
        '/admin-dashboard': (_) => const AdminDashboardScreen(),
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          textStyle: AppTextStyles.buttonLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppColors.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: AppColors.surfaceVariant,
      ),
      useMaterial3: true,
    );
  }
}

/// Wrapper pentru onboarding care marchează completarea la final
class _OnboardingWrapper extends StatelessWidget {
  const _OnboardingWrapper();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: const OnboardingWizardScreen(),
    );
  }
}

/// Ecran principal cu navigation drawer
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  @override
  Widget build(BuildContext context) {
    _markOnboardingDone();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('FriendsRide'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notificări',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _buildBody(context),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white30,
                  child: Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 8),
                Text('FriendsRide',
                    style: AppTextStyles.headingMedium
                        .copyWith(color: Colors.white)),
                Text('Versiunea 1.0.0',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white70)),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home_outlined,
            title: 'Acasă',
            route: '/home',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.tune,
            title: 'Preferințe cursă',
            route: '/ride-preferences',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.people_alt_outlined,
            title: 'Invită prieteni',
            route: '/referral',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.card_giftcard,
            title: 'Cursă cadou',
            route: '/gift-ride',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.schedule,
            title: 'Curse programate',
            route: '/scheduled-rides',
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.analytics_outlined,
            title: 'Dashboard Admin',
            route: '/admin-dashboard',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.login,
            title: 'Autentificare',
            route: '/login',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: AppTextStyles.menuItem),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed(route);
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWelcomeBanner(),
          const SizedBox(height: 24),
          _buildQuickActions(context),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bun venit!',
            style: AppTextStyles.displaySmall.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Unde mergi azi?',
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text('Caută destinație...',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(icon: Icons.tune, label: 'Preferințe', route: '/ride-preferences'),
      _QuickAction(icon: Icons.people_alt, label: 'Referral', route: '/referral'),
      _QuickAction(icon: Icons.card_giftcard, label: 'Cadou', route: '/gift-ride'),
      _QuickAction(icon: Icons.schedule, label: 'Programate', route: '/scheduled-rides'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acțiuni rapide', style: AppTextStyles.headingMedium),
        const SizedBox(height: 12),
        Row(
          children: actions.map((a) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => Navigator.of(context).pushNamed(a.route),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(a.icon, color: AppColors.primary, size: 28),
                        const SizedBox(height: 4),
                        Text(a.label,
                            style: AppTextStyles.labelSmall,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Activitate recentă', style: AppTextStyles.headingMedium),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.history, size: 40, color: AppColors.textDisabled),
                  const SizedBox(height: 8),
                  Text('Nicio cursă recentă',
                      style: AppTextStyles.bodyMedium),
                  Text('Cursele tale vor apărea aici',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String route;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.route,
  });
}
