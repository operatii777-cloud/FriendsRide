import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:friendsride_app/models/referral_model.dart';
import 'package:friendsride_app/services/referral_service.dart';
import 'package:friendsride_app/theme/app_colors.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';

/// Ecran pentru sistemul de referral - Invită prieteni și câștigă recompense
class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final ReferralService _referralService = ReferralService();
  ReferralStats? _stats;
  List<Referral> _referrals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final stats = await _referralService.getReferralStats(userId);
    final referrals = await _referralService.getReferrals(userId);

    if (mounted) {
      setState(() {
        _stats = stats;
        _referrals = referrals;
        _isLoading = false;
      });
    }
  }

  void _copyCode() {
    if (_stats?.referralCode == null) return;
    Clipboard.setData(ClipboardData(text: _stats!.referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cod copiat în clipboard!'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareCode() {
    if (_stats?.referralCode == null) return;
    Share.share(
      'Folosește codul meu de referral ${_stats!.referralCode} și primești 10 RON reducere la prima cursă cu FriendsRide! Descarcă aplicația acum.',
      subject: 'Invitație FriendsRide',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Invită Prieteni'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildReferralCodeCard(),
                    const SizedBox(height: 16),
                    _buildStatsCard(),
                    const SizedBox(height: 16),
                    _buildHowItWorksCard(),
                    const SizedBox(height: 16),
                    _buildReferralsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReferralCodeCard() {
    final code = _stats?.referralCode ?? '---';
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.people_alt_rounded, size: 48, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              'Codul tău de referral',
              style: AppTextStyles.headingSmall.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyCode,
                    icon: const Icon(Icons.copy, color: Colors.white),
                    label: const Text('Copiază', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareCode,
                    icon: const Icon(Icons.share),
                    label: const Text('Distribuie'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistici', style: AppTextStyles.headingMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem(
                  icon: Icons.group_add,
                  value: '${_stats?.totalReferrals ?? 0}',
                  label: 'Invitații totale',
                  color: AppColors.primary,
                ),
                _buildStatItem(
                  icon: Icons.check_circle,
                  value: '${_stats?.completedReferrals ?? 0}',
                  label: 'Completate',
                  color: AppColors.success,
                ),
                _buildStatItem(
                  icon: Icons.monetization_on,
                  value: '${(_stats?.totalRewardsEarned ?? 0).toStringAsFixed(0)} RON',
                  label: 'Câștigat',
                  color: AppColors.accent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.headingMedium.copyWith(color: color)),
          Text(label, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cum funcționează?', style: AppTextStyles.headingMedium),
            const SizedBox(height: 12),
            _buildStep(
              step: '1',
              title: 'Distribuie codul',
              description: 'Trimite codul tău unic prietenilor tăi.',
            ),
            _buildStep(
              step: '2',
              title: 'Prietenul se înregistrează',
              description: 'Prietenul descarcă aplicația și folosește codul tău.',
            ),
            _buildStep(
              step: '3',
              title: 'Amândoi câștigați',
              description: 'Tu primești 15 RON, iar prietenul tău primește 10 RON reducere!',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required String step,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildReferralsList() {
    if (_referrals.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.people_outline, size: 48, color: AppColors.textDisabled),
              const SizedBox(height: 8),
              Text('Nu ai invitat pe nimeni încă', style: AppTextStyles.bodyMedium),
              Text(
                'Distribuie codul tău și câștigă recompense!',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Invitații tale', style: AppTextStyles.headingMedium),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _referrals.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final referral = _referrals[index];
              return _buildReferralItem(referral);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReferralItem(Referral referral) {
    final statusColor = _statusColor(referral.status);
    final statusLabel = _statusLabel(referral.status);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.15),
        child: Icon(_statusIcon(referral.status), color: statusColor, size: 20),
      ),
      title: Text(
        referral.referredEmail ?? referral.referredPhone ?? 'Utilizator anonim',
        style: AppTextStyles.bodyMedium,
      ),
      subtitle: Text(
        'Creat: ${_formatDate(referral.createdAt.toDate())}',
        style: AppTextStyles.bodySmall,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Color _statusColor(ReferralStatus status) {
    switch (status) {
      case ReferralStatus.pending:
        return AppColors.warning;
      case ReferralStatus.completed:
        return AppColors.primary;
      case ReferralStatus.rewarded:
        return AppColors.success;
      case ReferralStatus.expired:
        return AppColors.textDisabled;
    }
  }

  IconData _statusIcon(ReferralStatus status) {
    switch (status) {
      case ReferralStatus.pending:
        return Icons.hourglass_empty;
      case ReferralStatus.completed:
        return Icons.check_circle_outline;
      case ReferralStatus.rewarded:
        return Icons.star;
      case ReferralStatus.expired:
        return Icons.timer_off;
    }
  }

  String _statusLabel(ReferralStatus status) {
    switch (status) {
      case ReferralStatus.pending:
        return 'În așteptare';
      case ReferralStatus.completed:
        return 'Completat';
      case ReferralStatus.rewarded:
        return 'Recompensat';
      case ReferralStatus.expired:
        return 'Expirat';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
