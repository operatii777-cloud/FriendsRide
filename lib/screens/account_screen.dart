import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:friendsride_app/screens/auth_screen.dart';
import 'package:friendsride_app/screens/personal_info_screen.dart';
import 'package:friendsride_app/screens/saved_addresses_screen.dart';
import 'package:friendsride_app/screens/security_screen.dart';
import 'package:friendsride_app/screens/wallet_screen.dart';
import 'package:friendsride_app/screens/history_screen.dart';
import 'package:friendsride_app/screens/receipts_screen.dart';
import 'package:friendsride_app/services/firestore_service.dart';
import 'package:friendsride_app/screens/passenger_scheduled_rides_screen.dart';
import 'package:friendsride_app/screens/driver_scheduled_rides_screen.dart';
import 'package:friendsride_app/widgets/driver_verification_badge_widget.dart';
import 'package:friendsride_app/models/driver_verification_model.dart';
import 'package:friendsride_app/screens/ride_preferences_screen.dart';
import 'package:friendsride_app/utils/logger.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  // ✅ NOU: Obține verificările șoferului
  Future<List<DriverVerification>> _getDriverVerifications() async {
    try {
      // Note: Driver verifications will be loaded from Firestore in future update
      // For now, return empty list
      return [];
    } catch (e) {
      Logger.error('Error getting driver verifications: $e', error: e);
      return [];
    }
  }

  Widget _buildMenuOption(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil'),
          ),
          body: StreamBuilder(
            stream: _firestoreService.getUserProfileStream(),
            builder: (context, profileSnapshot) {
              if (!profileSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final userData = profileSnapshot.data?.data();
              final bool isDriver = userData?['role'] == 'driver';

              return SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      width: double.infinity,
                      color: Colors.grey[100],
                      child: Column(
                        children: [
                          const Icon(Icons.account_circle, size: 80, color: Colors.blue),
                          const SizedBox(height: 16),
                          Text(
                            user?.displayName ?? userData?['displayName'] ?? 'Nume Utilizator',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            user?.email ?? 'email@exemplu.com',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          if (isDriver) ...[
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Șofer Partener',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            // ✅ NOU: Badge-uri de verificare
                            const SizedBox(height: 8),
                            FutureBuilder<List<DriverVerification>>(
                              future: _getDriverVerifications(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                  final badges = snapshot.data!
                                      .map((v) => DriverVerificationBadge.fromVerification(v))
                                      .toList();
                                  return DriverVerificationBadgesList(
                                    badges: badges,
                                    compact: true,
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildMenuOption(
                      icon: Icons.person_outline,
                      title: isDriver ? 'Detalii șofer partener și autovehicul' : 'Informații personale',
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (ctx) => const PersonalInfoScreen()));
                      },
                    ),
                    
                    _buildMenuOption(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Portofel',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const WalletScreen()));
                      },
                    ),
                    
                    _buildMenuOption(
                      icon: Icons.security_outlined,
                      title: 'Siguranță și Securitate',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const SecurityScreen()));
                      },
                    ),
                    
                     _buildMenuOption(
                      icon: Icons.home_work_outlined,
                      title: 'Adrese salvate',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const SavedAddressesScreen()));
                      },
                    ),
                    
                    // ✅ NOU: Preferințe cursă
                    _buildMenuOption(
                      icon: Icons.settings,
                      title: 'Preferințe cursă',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const RidePreferencesScreen()));
                      },
                    ),
                    
                    _buildMenuOption(
                      icon: Icons.history_outlined,
                      title: 'Istoric curse',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const HistoryScreen()));
                      },
                    ),

                    _buildMenuOption(
                      icon: Icons.calendar_month_outlined,
                      title: 'Rezervările mele (Pasager)',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const PassengerScheduledRidesScreen()));
                      },
                    ),

                    if (isDriver)
                      _buildMenuOption(
                        icon: Icons.event_note_outlined,
                        title: 'Curse programate (Șofer)',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (ctx) => const DriverScheduledRidesScreen()));
                        },
                      ),
                    
                    _buildMenuOption(
                      icon: Icons.receipt_long_outlined,
                      title: 'Chitantele tale',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ReceiptsScreen()));
                      },
                    ),
                    
                    const Divider(),
                    
                     _buildMenuOption(
                      icon: Icons.delete_forever_outlined,
                      title: 'Șterge contul',
                      onTap: () => _showDeleteAccountDialog(context),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Șterge contul permanent'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Această acțiune este ireversibilă. Pentru a confirma, vă rugăm introduceți parola contului dvs.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Parola',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vă rugăm introduceți parola.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // --- MODIFICARE: Salvăm referințele la Navigator și ScaffoldMessenger înainte de 'await' ---
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                // Închide dialogul curent de parolă
                Navigator.of(dialogContext).pop();

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => const Center(child: CircularProgressIndicator()),
                );

                final result = await _firestoreService.deleteUserAccount(
                  password: passwordController.text,
                );

                // --- MODIFICARE: Verificăm 'mounted' înainte de a folosi contextul salvat ---
                if (!mounted) return;

                // Închide dialogul de încărcare folosind referința salvată
                navigator.pop(); 

                if (result['success']) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: Colors.green,
                    ),
                  );
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (ctx) => const AuthScreen()),
                    (route) => false,
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Șterge Contul', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}