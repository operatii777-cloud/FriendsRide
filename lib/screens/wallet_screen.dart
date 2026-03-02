import 'package:flutter/material.dart';
import 'package:friendsride_app/screens/payment_methods_screen.dart';
import 'package:friendsride_app/screens/vouchers_screen.dart';
import 'package:friendsride_app/services/firestore_service.dart';
import 'package:friendsride_app/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  double _walletBalance = 0.00;
  bool _isLoading = true;
  int _voucherCount = 0;
  List<Map<String, dynamic>> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _loadWalletData();
    _setupStreams();
  }

  void _setupStreams() {
    // Listen to wallet balance changes
    _firestoreService.getWalletBalanceStream().listen((balance) {
      if (mounted) {
        setState(() => _walletBalance = balance);
      }
    });

    // Listen to payment methods changes
    _firestoreService.getPaymentMethodsStream().listen((methods) {
      if (mounted) {
        setState(() {
          _paymentMethods = [
            // Cash is always available
            {
              'type': 'cash',
              'brand': 'Numerar',
              'last4': null,
              'holderName': null,
              'canSendToContact': false,
            },
            ...methods,
          ];
        });
      }
    });
  }

  Future<void> _loadWalletData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Load wallet balance, voucher count, and payment methods
      final balance = await _firestoreService.getWalletBalance();
      final voucherCount = await _firestoreService.getVoucherCount();
      final paymentMethods = await _firestoreService.getPaymentMethods();

      if (mounted) {
        setState(() {
          _walletBalance = balance;
          _voucherCount = voucherCount;
          _paymentMethods = [
            // Cash is always available
            {
              'type': 'cash',
              'brand': 'Numerar',
              'last4': null,
              'holderName': null,
              'canSendToContact': false,
            },
            ...paymentMethods,
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading wallet data: $e');
      if (mounted) {
        setState(() {
          // Set defaults on error
          _paymentMethods = [
            {
              'type': 'cash',
              'brand': 'Numerar',
              'last4': null,
              'holderName': null,
              'canSendToContact': false,
            },
          ];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.wallet),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ FriendsRide Cash Card
                  _buildWalletCashCard(l10n),
                  
                  const SizedBox(height: 24),
                  
                  // ✅ Payment Methods Section
                  Text(
                    l10n.paymentMethods,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  ..._paymentMethods.map((method) => _buildPaymentMethodTile(method, l10n)),
                  
                  const SizedBox(height: 16),
                  
                  // ✅ Add Payment Method Button
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addPaymentMethod),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => const PaymentMethodsScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // ✅ Ride Profiles Section
                  Text(
                    l10n.rideProfiles,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Personal Profile
                  _buildRideProfileTile('Personal', Icons.person, l10n),
                  
                  const SizedBox(height: 12),
                  
                  // Business Profile - "Începe să folosești"
                  _buildBusinessProfileStartTile(l10n),
                  
                  const SizedBox(height: 12),
                  
                  // "Trimis mie" Section
                  _buildSentToMeSection(l10n),
                  
                  const SizedBox(height: 32),
                  
                  // ✅ Vouchers Section
                  Text(
                    l10n.vouchers,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildVoucherTile(l10n),
                  
                  const SizedBox(height: 8),
                  
                  _buildAddVoucherCodeTile(l10n),
                  
                  const SizedBox(height: 32),
                  
                  // ✅ Promotions Section
                  Text(
                    l10n.promotions,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildAddPromoCodeTile(l10n),
                  
                  const SizedBox(height: 32),
                  
                  // ✅ Recommendations Section
                  Text(
                    l10n.recommendations,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildAddReferralCodeTile(l10n),
                  
                  const SizedBox(height: 32),
                  
                  // ✅ In-Store Offers Section
                  Text(
                    l10n.inStoreOffers,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildInStoreOffersTile(l10n),
                ],
              ),
            ),
    );
  }

  Widget _buildWalletCashCard(AppLocalizations l10n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showWalletDetailsDialog(context, l10n);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FriendsRide Cash',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_walletBalance.toStringAsFixed(2)} RON',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(Map<String, dynamic> method, AppLocalizations l10n) {
    final isCash = method['type'] == 'cash';
    final brand = method['brand'] as String;
    final last4 = method['last4'] as String?;
    final holderName = method['holderName'] as String?;
    final canSendToContact = method['canSendToContact'] as bool;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildPaymentMethodIcon(brand, isCash),
        title: Text(
          holderName != null 
              ? '$holderName ($brand${last4 != null ? ' ••••$last4' : ''})'
              : brand,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: canSendToContact
            ? Text(
                l10n.canSendToContact,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () {
          _showPaymentMethodDetailsDialog(context, method, l10n);
        },
      ),
    );
  }

  Widget _buildPaymentMethodIcon(String brand, bool isCash) {
    if (isCash) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.money,
          color: Colors.green.shade700,
          size: 24,
        ),
      );
    }

    // Card brand icons
    if (brand == 'VISA') {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'VISA',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    } else if (brand == 'MasterCard') {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'MC',
            style: TextStyle(
              color: Colors.orange.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return const Icon(Icons.credit_card, size: 40);
  }

  Widget _buildRideProfileTile(String profileName, IconData icon, AppLocalizations l10n) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.black,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          profileName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () {
          // Personal profile is always active, no details needed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.personalProfileActive)),
          );
        },
      ),
    );
  }

  Widget _buildBusinessProfileStartTile(AppLocalizations l10n) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.startUsing,
              style: TextStyle(
                color: Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.business_center,
                    color: Colors.grey.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.friendsRideForBusiness,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.activateBusinessFeatures,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentToMeSection(AppLocalizations l10n) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, color: Colors.grey.shade700, size: 18),
              const SizedBox(width: 2),
              Icon(Icons.add, color: Colors.grey.shade700, size: 14),
            ],
          ),
        ),
        title: Text(
          l10n.manageBusinessTrips,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          l10n.requestBusinessProfileAccess,
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () {
          _showBusinessProfileRequestDialog(context, l10n);
        },
      ),
    );
  }

  Widget _buildVoucherTile(AppLocalizations l10n) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.local_offer, size: 24),
        title: Text(
          l10n.vouchers,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: Text(
          '$_voucherCount',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const VouchersScreen()),
          );
        },
      ),
    );
  }

  Widget _buildAddVoucherCodeTile(AppLocalizations l10n) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.add, size: 24),
        title: Text(
          l10n.addVoucherCode,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const VouchersScreen()),
          );
        },
      ),
    );
  }

  Widget _buildAddPromoCodeTile(AppLocalizations l10n) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.add, size: 24),
        title: Text(
          l10n.addPromoCode,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const VouchersScreen()),
          );
        },
      ),
    );
  }

  Widget _buildAddReferralCodeTile(AppLocalizations l10n) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.add, size: 24),
        title: Text(
          l10n.addReferralCode,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        onTap: () {
          _showReferralCodeDialog(context, l10n);
        },
      ),
    );
  }

  Widget _buildInStoreOffersTile(AppLocalizations l10n) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.local_offer, size: 24),
        title: Text(
          l10n.offers,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.inStoreOffersComingSoon)),
          );
        },
      ),
    );
  }

  void _showWalletDetailsDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.walletDetails),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.currentBalance}: ${_walletBalance.toStringAsFixed(2)} RON'),
            const SizedBox(height: 16),
            Text(l10n.walletDetailsInfo),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to add funds - placeholder pentru viitor
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.addFundsComingSoon)),
              );
            },
            child: Text(l10n.addFunds),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodDetailsDialog(
    BuildContext context,
    Map<String, dynamic> method,
    AppLocalizations l10n,
  ) {
    final isCash = method['type'] == 'cash';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.paymentMethodDetails),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCash) ...[
              Text('${l10n.brand}: ${method['brand']}'),
              if (method['last4'] != null)
                Text('${l10n.last4Digits}: ••••${method['last4']}'),
              if (method['holderName'] != null)
                Text('${l10n.cardholder}: ${method['holderName']}'),
              if (method['expiryMonth'] != null && method['expiryYear'] != null)
                Text('${l10n.expiryDate}: ${method['expiryMonth']}/${method['expiryYear']}'),
            ] else
              Text(l10n.cashPaymentMethod),
            const SizedBox(height: 16),
            if (method['canSendToContact'] == true)
              Text(l10n.canSendToContact, style: TextStyle(color: Colors.blue)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
          if (!isCash)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await _firestoreService.deletePaymentMethod(method['id'] as String);
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.paymentMethodDeleted),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.errorDeletingPaymentMethod),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(l10n.delete, style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  void _showBusinessProfileRequestDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.businessProfile),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.businessProfileInfo),
            const SizedBox(height: 16),
            Text(l10n.businessProfileBenefits, style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('• ${l10n.businessProfileBenefit1}'),
            Text('• ${l10n.businessProfileBenefit2}'),
            Text('• ${l10n.businessProfileBenefit3}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                // Placeholder pentru datele companiei - în viitor se va adăuga formular
                // Notă: Acest placeholder va fi înlocuit cu un formular complet pentru datele companiei
                await _firestoreService.requestBusinessProfile(
                  companyName: 'Company Name',
                  companyEmail: 'company@example.com',
                );
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.businessProfileRequestSent),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.errorRequestingBusinessProfile),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.requestAccess),
          ),
        ],
      ),
    );
  }

  void _showReferralCodeDialog(BuildContext context, AppLocalizations l10n) {
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addReferralCode),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.referralCodeInfo),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                hintText: l10n.enterReferralCode,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isNotEmpty) {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final result = await _firestoreService.validateReferralCode(codeController.text);
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(result['message'] as String),
                        backgroundColor: result['success'] as bool ? Colors.green : Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.errorApplyingReferralCode),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(l10n.apply),
          ),
        ],
      ),
    );
  }
}
