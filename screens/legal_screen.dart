import 'package:flutter/material.dart';
import 'package:friendsride_app/l10n/app_localizations.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Două tab-uri: Termeni și Confidențialitate
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.legalInformation),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: const Icon(Icons.gavel_rounded), text: AppLocalizations.of(context)!.termsConditions),
              Tab(icon: const Icon(Icons.shield_outlined), text: AppLocalizations.of(context)!.privacy),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Conținutul pentru primul tab (Termeni și Condiții)
            _buildTermsAndConditionsTab(context),
            
            // Conținutul pentru al doilea tab (Confidențialitate)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                AppLocalizations.of(context)!.privacyPolicyContent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pentru construirea conținutului din primul tab
  Widget _buildTermsAndConditionsTab(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.termsConditionsTitle,
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(context, AppLocalizations.of(context)!.generalProvisions),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.generalProvisionsText,
            ),
            const SizedBox(height: 16),
            
            _buildSectionTitle(context, AppLocalizations.of(context)!.standardWaitTime),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.standardWaitTimeText,
            ),
            const SizedBox(height: 24),
            
            Text(
              AppLocalizations.of(context)!.specificCategoryPolicies,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),

            _buildCategoryPolicy(
              context: context,
              category: AppLocalizations.of(context)!.friendsRideStandard,
              cancellationFee: AppLocalizations.of(context)!.standardCancellationFee,
              freeCancellation: AppLocalizations.of(context)!.standardFreeCancellation,
              minBookingTime: AppLocalizations.of(context)!.standardMinBooking,
            ),
            const Divider(height: 24),
            
            _buildCategoryPolicy(
              context: context,
              category: AppLocalizations.of(context)!.friendsRideEnergy,
              cancellationFee: AppLocalizations.of(context)!.standardCancellationFee,
              freeCancellation: AppLocalizations.of(context)!.standardFreeCancellation,
              minBookingTime: AppLocalizations.of(context)!.standardMinBooking,
            ),
            const Divider(height: 24),

            _buildCategoryPolicy(
              context: context,
              category: AppLocalizations.of(context)!.friendsRideBest,
              cancellationFee: AppLocalizations.of(context)!.standardCancellationFee,
              freeCancellation: AppLocalizations.of(context)!.standardFreeCancellation,
              minBookingTime: AppLocalizations.of(context)!.standardMinBooking,
            ),
            const Divider(height: 24),
            
            _buildCategoryPolicy(
              context: context,
              category: AppLocalizations.of(context)!.friendsRideFamily,
              cancellationFee: AppLocalizations.of(context)!.standardCancellationFee,
              freeCancellation: AppLocalizations.of(context)!.standardFreeCancellation,
              minBookingTime: AppLocalizations.of(context)!.standardMinBooking,
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widgets pentru a structura conținutul
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
  
  Widget _buildCategoryPolicy({
    required BuildContext context,
    required String category,
    required String cancellationFee,
    required String freeCancellation,
    required String minBookingTime,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildPolicyDetail(
          context: context,
          icon: Icons.money_off,
          title: AppLocalizations.of(context)!.cancellationFee,
          description: '$cancellationFee sau prețul preafișat al cursei (se va debita valoarea cea mai mică).',
        ),
        const SizedBox(height: 8),
        _buildPolicyDetail(
          context: context,
          icon: Icons.event_available,
          title: AppLocalizations.of(context)!.freeCancellation,
          description: freeCancellation,
        ),
        const SizedBox(height: 8),
        _buildPolicyDetail(
          context: context,
          icon: Icons.timer,
          title: AppLocalizations.of(context)!.minimumBookingTime,
          description: minBookingTime,
        ),
      ],
    );
  }
  
  Widget _buildPolicyDetail({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}