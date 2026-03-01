import 'package:flutter/material.dart';
import 'package:friendsride_app/services/social_auth_service.dart';
import 'package:friendsride_app/theme/app_colors.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';

/// Ecran de autentificare prin rețele sociale
class SocialLoginScreen extends StatefulWidget {
  const SocialLoginScreen({super.key});

  @override
  State<SocialLoginScreen> createState() => _SocialLoginScreenState();
}

class _SocialLoginScreenState extends State<SocialLoginScreen> {
  final SocialAuthService _authService = SocialAuthService();
  bool _isLoading = false;
  String? _loadingProvider;

  Future<void> _signIn(String provider) async {
    setState(() {
      _isLoading = true;
      _loadingProvider = provider;
    });

    try {
      dynamic result;
      switch (provider) {
        case 'google':
          result = await _authService.signInWithGoogle();
          break;
        case 'apple':
          result = await _authService.signInWithApple();
          break;
        case 'facebook':
          result = await _authService.signInWithFacebook();
          break;
      }

      if (result != null && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autentificarea a fost anulată.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la autentificare: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingProvider = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              _buildLogo(),
              const SizedBox(height: 48),
              _buildTitle(),
              const SizedBox(height: 48),
              _buildSocialButtons(),
              const SizedBox(height: 24),
              _buildDivider(),
              const SizedBox(height: 24),
              _buildGuestButton(),
              const SizedBox(height: 32),
              _buildTerms(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_car_rounded,
            size: 56,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'FriendsRide',
          style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Cursele tale, pe bună prietenie',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Conectează-te pentru a continua',
          style: AppTextStyles.headingSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        _SocialButton(
          label: 'Continuă cu Google',
          icon: Icons.g_mobiledata_rounded,
          iconColor: const Color(0xFFDB4437),
          backgroundColor: Colors.white,
          textColor: AppColors.textPrimary,
          borderColor: AppColors.textDisabled,
          isLoading: _isLoading && _loadingProvider == 'google',
          onTap: _isLoading ? null : () => _signIn('google'),
        ),
        const SizedBox(height: 12),
        _SocialButton(
          label: 'Continuă cu Apple',
          icon: Icons.apple_rounded,
          iconColor: Colors.black,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          isLoading: _isLoading && _loadingProvider == 'apple',
          onTap: _isLoading ? null : () => _signIn('apple'),
        ),
        const SizedBox(height: 12),
        _SocialButton(
          label: 'Continuă cu Facebook',
          icon: Icons.facebook_rounded,
          iconColor: Colors.white,
          backgroundColor: const Color(0xFF1877F2),
          textColor: Colors.white,
          isLoading: _isLoading && _loadingProvider == 'facebook',
          onTap: _isLoading ? null : () => _signIn('facebook'),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('sau', style: AppTextStyles.bodySmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGuestButton() {
    return OutlinedButton(
      onPressed: _isLoading
          ? null
          : () => Navigator.of(context).pushReplacementNamed('/home'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        'Continuă ca vizitator',
        style: AppTextStyles.buttonLarge.copyWith(color: AppColors.primary),
      ),
    );
  }

  Widget _buildTerms() {
    return Text(
      'Prin continuare, ești de acord cu Termenii de utilizare și Politica de confidențialitate FriendsRide.',
      style: AppTextStyles.bodySmall,
      textAlign: TextAlign.center,
    );
  }
}

/// Buton de social login reutilizabil
class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final bool isLoading;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: borderColor != null
                ? BorderSide(color: borderColor!)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 26),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
