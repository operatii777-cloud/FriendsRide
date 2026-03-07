import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:friendsride_app/l10n/app_localizations.dart';
import 'package:friendsride_app/providers/locale_provider.dart';
import 'package:friendsride_app/screens/about_screen.dart';
// ignore: unused_import
import 'package:friendsride_app/screens/account_screen.dart';
import 'package:friendsride_app/screens/auth_screen.dart';
import 'package:friendsride_app/screens/driver_application_screen.dart';
import 'package:friendsride_app/screens/help_screen.dart';
import 'package:friendsride_app/screens/legal_screen.dart';
import 'package:friendsride_app/screens/ride_request_screen.dart';
import 'package:friendsride_app/screens/safety_screen.dart';
import 'package:friendsride_app/screens/subscriptions_screen.dart';
import 'package:friendsride_app/screens/join_team_screen.dart';
import 'package:friendsride_app/services/firestore_service.dart';
import 'package:friendsride_app/screens/driver_dashboard_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:friendsride_app/screens/personal_info_screen.dart';
import 'package:friendsride_app/theme/theme_provider.dart';
import 'package:friendsride_app/providers/assistant_status_provider.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';

// --- MODIFICAT: Am adăugat importurile necesare ---
import 'package:friendsride_app/screens/history_screen.dart';
import 'package:friendsride_app/screens/receipts_screen.dart';
import 'package:friendsride_app/screens/wallet_screen.dart';
import 'package:friendsride_app/screens/voice_settings_screen.dart';
import 'package:friendsride_app/screens/voice_demo_screen.dart';
import 'package:friendsride_app/widgets/microphone_test.dart';
import 'package:friendsride_app/screens/splash_screen.dart';
import 'package:friendsride_app/screens/ai_vocabulary_test_screen.dart'; // Adăugat import
import 'package:friendsride_app/delivery/screens/restaurant_list_screen.dart'; // Delivery
// -------------------------------------------------

class AppDrawer extends StatelessWidget {
  final UserRole currentRole;
  final Function(bool) onRoleChanged;
  static bool lowDataMode = false;
  static bool showPerfOverlay = false;

  const AppDrawer({
    super.key,
    required this.currentRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final FirestoreService firestoreService = FirestoreService();

    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: firestoreService.getUserProfileStream(),
              builder: (context, snapshot) {
                String displayName = 'Utilizator';
                String email = FirebaseAuth.instance.currentUser?.email ?? '';
                String phoneNumber = '';
                ImageProvider? profileImage;

                if (snapshot.connectionState == ConnectionState.active && snapshot.hasData) {
                  final data = snapshot.data?.data();
                  if (data != null) {
                    displayName = data['displayName'] ?? displayName;
                    phoneNumber = data['phoneNumber'] ?? '';
                    final photoURL = data['photoURL'] as String?;
                    if (photoURL != null) {
                      profileImage = NetworkImage(photoURL);
                    }
                  }
                }

                return Container(
                  height: 140, // Înălțime redusă pentru a evita overflow-ul
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(color: Colors.blue),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 25, // Redus și mai mult
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        backgroundImage: profileImage,
                        child: profileImage == null
                            ? Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                style: TextStyle(fontSize: 24.0, color: Theme.of(context).primaryColor),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      // Informații utilizator
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              displayName,
                              style: AppTextStyles.menuHeader.copyWith(
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: AppTextStyles.menuSubtitle.copyWith(
                                color: Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            if (phoneNumber.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                phoneNumber,
                                style: AppTextStyles.menuSubtitle.copyWith(
                                  color: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            if (currentRole == UserRole.passenger) ...[
              ListTile(
                dense: true,
                leading: const Icon(Icons.group_add_outlined, color: Colors.blue),
                title: Text(
                  l10n.joinTeam,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const JoinTeamScreen()),
              ),

              ListTile(
                dense: true,
                leading: const Icon(Icons.drive_eta_outlined, color: Colors.green),
                title: Text(
                  l10n.applyForDriver,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const DriverApplicationScreen()),
              ),

              const Divider(height: 1),

              ListTile(
                dense: true,
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(
                  l10n.profile,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const PersonalInfoScreen()),
              ),
              
              // --- MODIFICAT: Am adăugat opțiunile de meniu ---
              ListTile(
                dense: true,
                leading: const Icon(Icons.history_outlined),
                title: Text(
                  l10n.rideHistory,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const HistoryScreen()),
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(
                  l10n.receipts,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const ReceiptsScreen()),
              ),
              
              // ✅ NOU: Portofel entry
              ListTile(
                dense: true,
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(
                  l10n.wallet,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const WalletScreen()),
              ),
              // ----------------------------------------------------

              ListTile(
                dense: true,
                leading: const Icon(Icons.card_membership_outlined),
                title: Text(
                  l10n.subscriptions,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const SubscriptionsScreen()),
              ),

              ListTile(
                dense: true,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(
                  l10n.scheduleRide,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final position = await Geolocator.getCurrentPosition();

                  if (!navigator.mounted) return;

                  navigator.pop();
                  navigator.push(MaterialPageRoute(
                    builder: (ctx) => RideRequestScreen(
                      startPosition: position,
                      isScheduling: true,
                    ),
                  ));
                },
              ),

              ListTile(
                dense: true,
                leading: const Icon(Icons.vpn_key, color: Colors.orange),
                title: Text(
                  l10n.activateDriverCode,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _showDriverCodeActivationDialog(context),
              ),

              const Divider(height: 1),

              // ✅ NOU: Delivery entry
              ListTile(
                dense: true,
                leading: const Icon(Icons.restaurant_menu, color: Colors.orange),
                title: Text(
                  'Delivery',
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const RestaurantListScreen()),
              ),

              ListTile(
                dense: true,
                leading: const Icon(Icons.security_outlined),
                title: Text(
                  l10n.safety,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const SafetyScreen()),
              ),

              ListTile(
                dense: true,
                leading: const Icon(Icons.help_outline),
                title: Text(
                  l10n.help,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateToWithRole(context, const HelpScreen(isPassengerMode: true)),
              ),

              SwitchListTile(
                dense: true,
                secondary: const Icon(Icons.data_saver_on_outlined),
                title: Text(
                  l10n.lowDataMode,
                  style: AppTextStyles.menuItem,
                ),
                value: lowDataMode,
                onChanged: (v) {
                  lowDataMode = v;
                  Navigator.of(context).pop();
                },
              ),

              // High-contrast toggle
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => SwitchListTile(
                  secondary: const Icon(Icons.contrast_outlined),
                  title: Text(
                    l10n.highContrastUI,
                    style: AppTextStyles.menuItem,
                  ),
                  value: themeProvider.isHighContrast,
                  onChanged: (v) {
                    themeProvider.toggleHighContrast();
                    Navigator.of(context).pop();
                  },
                ),
              ),

              // Assistant status overlay toggle
              Consumer<AssistantStatusProvider>(
                builder: (context, sp, _) => SwitchListTile(
                  secondary: const Icon(Icons.assistant_outlined),
                  title: Text(
                    l10n.assistantStatusOverlay,
                    style: AppTextStyles.menuItem,
                  ),
                  value: sp.overlayEnabled,
                  onChanged: (v) {
                    sp.setOverlayEnabled(v);
                    Navigator.of(context).pop();
                  },
                ),
              ),
              
              ExpansionTile(
                dense: true,
                leading: const Icon(Icons.assistant_outlined, color: Colors.blue),
                title: Text(
                  l10n.aiAssistant,
                  style: AppTextStyles.menuItem,
                ),
                children: [
            ListTile(
              dense: true,
                    leading: const Icon(Icons.mic, color: Colors.blue),
                    title: Text(
                      l10n.voiceSettings,
                      style: AppTextStyles.menuItem,
                    ),
                    onTap: () => _navigateTo(context, const VoiceSettingsScreen()),
                  ),
            if (kDebugMode)
              ListTile(
                dense: true,
                    leading: const Icon(Icons.voice_chat, color: Colors.green),
                    title: Text(
                      l10n.voiceDemo,
                      style: AppTextStyles.menuItem,
                    ),
                    onTap: () => _navigateTo(context, const VoiceDemoScreen()),
                  ),
            if (kDebugMode)
              ListTile(
                dense: true,
                    leading: const Icon(Icons.mic_external_on_outlined, color: Colors.orange),
                    title: Text(
                      l10n.microphoneTest,
                      style: AppTextStyles.menuItem,
                    ),
                    onTap: () => _navigateTo(context, const MicrophoneTest()),
                  ),
            if (kDebugMode)
              ListTile(
                dense: true,
                    leading: const Icon(Icons.psychology, color: Colors.purple),
                    title: Text(
                      l10n.aiLibraryTest,
                      style: AppTextStyles.menuItem,
                    ),
                    onTap: () => _navigateTo(context, const AIVocabularyTestScreen()),
                  ),
                ],
              ),

              SwitchListTile(
                dense: true,
                secondary: const Icon(Icons.speed),
                title: Text(
                  l10n.performanceOverlay,
                  style: AppTextStyles.menuItem,
                ),
                value: showPerfOverlay,
                onChanged: (v) {
                  showPerfOverlay = v;
                  // Repornește aplicația la nivel de MaterialApp prin mutare la o nouă rută
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (ctx) => const SplashScreen()),
                  );
                },
              ),

              // Mutat în submeniul „Asistent AI”

              ListTile(
                dense: true,
                leading: const Icon(Icons.info_outline),
                title: Text(
                  l10n.about,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateToWithRole(context, const AboutScreen(isPassengerMode: true)),
              ),

              ListTile(
                dense: true,
                leading: const Icon(Icons.gavel_outlined),
                title: Text(
                  l10n.legal,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const LegalScreen()),
              ),

              ListTile(
                dense: true,
                leading: const Icon(Icons.language),
                title: Text(
                  l10n.language,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _showLanguagePicker(context),
              ),

              const Divider(thickness: 2, color: Colors.red),

              Container(
                color: Colors.red.withAlpha(25),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red, size: 28),
                  title: Text(
                    l10n.logout,
                    style: AppTextStyles.menuItemDanger,
                  ),
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    await FirebaseAuth.instance.signOut();
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const AuthScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
              ),

            ] else if (currentRole == UserRole.driver) ...[
              ListTile(
                dense: true,
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(
                  l10n.profile,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const PersonalInfoScreen()),
              ),
              
              // --- MODIFICAT: Am adăugat opțiunile de meniu ---
              ListTile(
                dense: true,
                leading: const Icon(Icons.history_outlined),
                title: Text(
                  l10n.rideHistory,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const HistoryScreen()),
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(
                  l10n.receipts,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const ReceiptsScreen()),
              ),
              
              // ✅ NOU: Portofel entry pentru driver
              ListTile(
                dense: true,
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(
                  l10n.wallet,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const WalletScreen()),
              ),
              // ----------------------------------------------------

              ListTile(
                dense: true,
                leading: const Icon(Icons.dashboard_outlined, color: Colors.green),
                title: Text(
                  l10n.driverDashboard,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const DriverDashboardScreen()),
              ),

              ListTile(
                dense: true,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(
                  l10n.scheduleRide,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final position = await Geolocator.getCurrentPosition();

                  if (!navigator.mounted) return;

                  navigator.pop();
                  navigator.push(MaterialPageRoute(
                    builder: (ctx) => RideRequestScreen(
                      startPosition: position,
                      isScheduling: true,
                    ),
                  ));
                },
              ),

              ListTile(
                dense: true,
                leading: const Icon(Icons.card_membership_outlined),
                title: Text(
                  l10n.subscriptions,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const SubscriptionsScreen()),
              ),

              const Divider(height: 1),

              // ✅ NOU: Delivery entry pentru driver (poate fi curier)
              ListTile(
                dense: true,
                leading: const Icon(Icons.restaurant_menu, color: Colors.orange),
                title: Text(
                  'Delivery',
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const RestaurantListScreen()),
              ),

              ListTile(
                dense: true,
                leading: const Icon(Icons.security_outlined),
                title: Text(
                  l10n.safety,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const SafetyScreen()),
              ),

              ListTile(
                dense: true,
                leading: const Icon(Icons.help_outline),
                title: Text(
                  l10n.help,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateToWithRole(context, const HelpScreen(isPassengerMode: false)),
              ),
              
              ListTile(
                dense: true,
                leading: const Icon(Icons.mic, color: Colors.blue),
                title: Text(
                  l10n.aiVoiceSettings,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const VoiceSettingsScreen()),
              ),
              
              if (kDebugMode)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.voice_chat, color: Colors.green),
                  title: Text(
                    l10n.voiceAIDemo,
                    style: AppTextStyles.menuItem,
                  ),
                  onTap: () => _navigateTo(context, const VoiceDemoScreen()),
                ),
              
              if (kDebugMode)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.bug_report, color: Colors.orange),
                  title: Text(
                    l10n.microphoneTestTool,
                    style: AppTextStyles.menuItem,
                  ),
                  onTap: () => _navigateTo(context, const MicrophoneTest()),
                ),

              if (kDebugMode)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.psychology, color: Colors.purple),
                  title: Text(
                    l10n.aiLibraryTestTool,
                    style: AppTextStyles.menuItem,
                  ),
                  onTap: () => _navigateTo(context, const AIVocabularyTestScreen()),
                ),

              ListTile(
                dense: true,
                leading: const Icon(Icons.info_outline),
                title: Text(
                  l10n.about,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateToWithRole(context, const AboutScreen(isPassengerMode: false)),
              ),

              ListTile(
                dense: true,
                leading: const Icon(Icons.gavel_outlined),
                title: Text(
                  l10n.legal,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _navigateTo(context, const LegalScreen()),
              ),

              ListTile(
                dense: true,
                leading: const Icon(Icons.language),
                title: Text(
                  l10n.language,
                  style: AppTextStyles.menuItem,
                ),
                onTap: () => _showLanguagePicker(context),
              ),

              const Divider(height: 1),

              // ✅ FIX: Adăugat opțiuni de setări pentru driver (la fel ca pentru passenger)
              SwitchListTile(
                dense: true,
                secondary: const Icon(Icons.data_saver_on_outlined),
                title: Text(
                  l10n.lowDataMode,
                  style: AppTextStyles.menuItem,
                ),
                value: lowDataMode,
                onChanged: (v) {
                  lowDataMode = v;
                  Navigator.of(context).pop();
                },
              ),

              // High-contrast toggle
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => SwitchListTile(
                  secondary: const Icon(Icons.contrast_outlined),
                  title: Text(
                    l10n.highContrastUI,
                    style: AppTextStyles.menuItem,
                  ),
                  value: themeProvider.isHighContrast,
                  onChanged: (v) {
                    themeProvider.toggleHighContrast();
                    Navigator.of(context).pop();
                  },
                ),
              ),

              // Assistant status overlay toggle
              Consumer<AssistantStatusProvider>(
                builder: (context, sp, _) => SwitchListTile(
                  secondary: const Icon(Icons.assistant_outlined),
                  title: Text(
                    l10n.assistantStatusOverlay,
                    style: AppTextStyles.menuItem,
                  ),
                  value: sp.overlayEnabled,
                  onChanged: (v) {
                    sp.setOverlayEnabled(v);
                    Navigator.of(context).pop();
                  },
                ),
              ),

              const Divider(thickness: 2, color: Colors.red),

              Container(
                color: Colors.red.withAlpha(25),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red, size: 28),
                  title: Text(
                    l10n.logout,
                    style: AppTextStyles.menuItemDanger,
                  ),
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    await FirebaseAuth.instance.signOut();
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const AuthScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    if (!Navigator.of(context).mounted) return;
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => screen));
  }

  void _navigateToWithRole(BuildContext context, Widget screen) {
    if (!Navigator.of(context).mounted) return;
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => screen));
  }

  void _showLanguagePicker(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                provider.setLocale(const Locale('ro'));
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      provider.locale.languageCode == 'ro' 
                        ? Icons.radio_button_checked 
                        : Icons.radio_button_unchecked,
                      color: provider.locale.languageCode == 'ro' 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey,
                    ),
                    const SizedBox(width: 16),
                    Text(l10n.romanian),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () {
                provider.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      provider.locale.languageCode == 'en' 
                        ? Icons.radio_button_checked 
                        : Icons.radio_button_unchecked,
                      color: provider.locale.languageCode == 'en' 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey,
                    ),
                    const SizedBox(width: 16),
                    Text(l10n.english),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          )
        ],
      ),
    );
  }

  void _showDriverCodeActivationDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController codeController = TextEditingController();
    final FirestoreService firestoreService = FirestoreService();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.activateDriverCodeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.activateDriverCodeDescription,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              maxLength: 20,
              decoration: const InputDecoration(
                labelText: 'Cod de activare',
                border: OutlineInputBorder(),
                hintText: 'Ex: DRV-TEST-102',
                counterText: "",
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              codeController.dispose();
              Navigator.of(dialogContext).pop();
            },
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              if (code.isEmpty) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.enterActivationCode),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              if (code.length < 5) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.codeTooShort),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                Navigator.of(dialogContext).pop();

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingContext) => AlertDialog(
                    content: Row(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(width: 16),
                        Text(l10n.validatingCode),
                      ],
                    ),
                  ),
                );

                final success = await firestoreService.activateDriverWithCode(code);

                if (navigator.mounted) navigator.pop();

                if (success) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.codeActivatedSuccess),
                      backgroundColor: Colors.green,
                    ),
                  );
                  onRoleChanged(true);
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.codeInvalidOrUsed),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (navigator.mounted) {
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.errorValidatingCode(e.toString())),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                codeController.dispose();
              }
            },
            child: Text(l10n.activate),
          ),
        ],
      ),
    );
  }
}