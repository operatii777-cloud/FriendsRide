import 'package:flutter/material.dart';
import 'package:friendsride_app/models/subscription_model.dart';
import 'package:friendsride_app/l10n/app_localizations.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  // Listă simulată de planuri de abonament
  final List<SubscriptionPlan> _plans = [
    SubscriptionPlan(
      title: 'Friends Basic',
      description: 'Pentru călătorii ocazionali.',
      pricePerMonth: 19.99,
      benefits: [
        '5% reducere la 10 curse/lună',
        'Anulare gratuită în 2 minute',
      ],
    ),
    SubscriptionPlan(
      title: 'Friends Plus',
      description: 'Cel mai popular plan.',
      pricePerMonth: 39.99,
      benefits: [
        '10% reducere la toate cursele',
        'Anulare gratuită în 5 minute',
        'Suport prioritar 24/7',
      ],
      cardColor: Colors.blue.shade50,
      isRecommended: true,
    ),
    SubscriptionPlan(
      title: 'Friends Premium',
      description: 'Beneficii exclusive.',
      pricePerMonth: 79.99,
      benefits: [
        '15% reducere la toate cursele',
        'Anulare gratuită oricând',
        'Suport prioritar 24/7',
        'Acces la mașini premium',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subscriptionsTitle),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _plans.length,
        itemBuilder: (context, index) {
          final l10n = AppLocalizations.of(context)!;
          return _buildPlanCard(_plans[index], l10n);
        },
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, AppLocalizations l10n) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.only(bottom: 20.0),
      color: plan.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: plan.isRecommended
            ? BorderSide(color: Colors.blue.shade400, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.isRecommended)
              Chip(
                label: Text(l10n.recommended),
                backgroundColor: Colors.blue,
                labelStyle: const TextStyle(color: Colors.white),
              ),
            if (plan.isRecommended) const SizedBox(height: 8),
            Text(
              plan.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              plan.description,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${plan.pricePerMonth}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
                  child: Text(l10n.ronPerMonth, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // AICI ESTE CORECȚIA: Am eliminat '.toList()' care era inutil
            ...plan.benefits.map((benefit) => _buildBenefitRow(benefit)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Acțiune simulată
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.planSelected(plan.title)),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: plan.isRecommended ? Colors.blue : null,
                  foregroundColor: plan.isRecommended ? Colors.white : null,
                ),
                child: Text(l10n.choosePlan),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(String benefit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(benefit)),
        ],
      ),
    );
  }
}
