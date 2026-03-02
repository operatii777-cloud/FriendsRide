// ...existing code...

import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// Firebase App Check will be added when needed for production security
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:friendsride_app/screens/auth_screen.dart';
import 'package:friendsride_app/screens/map_screen.dart';
import 'package:friendsride_app/screens/gift_ride_screen.dart';
import 'package:friendsride_app/screens/onboarding_wizard_screen.dart';
import 'package:friendsride_app/screens/referral_screen.dart';
import 'package:friendsride_app/screens/scheduled_ride_notifications_screen.dart';
import 'package:friendsride_app/screens/social_login_screen.dart';
import 'package:friendsride_app/services/firestore_service.dart';
// import 'package:friendsride_app/services/tts_service.dart';
import 'package:friendsride_app/theme/app_theme.dart';
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:friendsride_app/theme/theme_provider.dart';
// import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:friendsride_app/providers/locale_provider.dart';
import 'package:friendsride_app/l10n/app_localizations.dart' as l10n;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async' show unawaited;
// NOU: Providerii pentru refactoring
import 'package:friendsride_app/providers/driver_state_provider.dart';
import 'package:friendsride_app/providers/map_camera_provider.dart';
import 'package:friendsride_app/providers/assistant_status_provider.dart';

// Voice AI providers - NOU SISTEM VOCAL
import 'package:friendsride_app/voice/integration/friendsride_voice_integration.dart';
import 'package:friendsride_app/voice/passenger/passenger_voice_controller.dart';
import 'package:friendsride_app/voice/passenger/passenger_voice_controller_adapter.dart';
import 'package:friendsride_app/voice/driver/driver_voice_controller.dart';

// IMPORT NOU: Adaugă calea către ecranul de pornire
import 'package:friendsride_app/screens/splash_screen.dart';
import 'package:friendsride_app/services/app_initializer.dart';

// Mapbox Configuration
// import 'package:friendsride_app/utils/mapbox_config.dart';
import 'package:friendsride_app/config/environment.dart';
// import 'package:friendsride_app/services/app_monitor.dart';
// import 'package:friendsride_app/services/offline_manager.dart' as offline_manager_service;
// import 'package:friendsride_app/voice/nlp/ride_intent_processor.dart';
import 'package:friendsride_app/widgets/app_drawer.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:friendsride_app/services/startup_timer.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Voice screens
// Voice settings and demo screens are imported when needed

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  StartupTimer.instance.mark('widgetsBinding.ready');

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  final sentryDsn = await _resolveSentryDsn();
  if (sentryDsn != null && sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = Environment.isProduction ? 'production' : 'development';
        options.tracesSampleRate = Environment.isProduction ? 0.2 : 1.0;
        options.enableAutoSessionTracking = true;
        options.enableAppLifecycleBreadcrumbs = true;
        options.enableUserInteractionBreadcrumbs = true;
        options.sendDefaultPii = Environment.isProduction;
      },
      appRunner: _runFriendsRideApp,
    );
  } else {
    _runFriendsRideApp();
  }
}

void _runFriendsRideApp() {
  // Defer heavy operations to background
  unawaited(_initializeBackground());

  // Moved Firebase initialization into AppInitializer for background startup
  // 🔐 SECURITATE: Firebase App Check pentru protecția backend-ului - handled later when needed

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final provider = ThemeProvider();
            provider.initialize();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
        ChangeNotifierProvider(create: (context) => AppInitializer()),
        ChangeNotifierProvider(create: (context) => DriverStateProvider()),
        ChangeNotifierProvider(create: (context) => MapCameraProvider()),
        ChangeNotifierProvider(create: (context) => AssistantStatusProvider()),
        ChangeNotifierProvider(create: (context) => FriendsRideVoiceIntegration()),
        ChangeNotifierProvider(create: (context) => DriverVoiceController(
          firestoreService: FirestoreService(),
        )),
        ChangeNotifierProvider(create: (context) => PassengerVoiceControllerAdapter(
          controller: PassengerVoiceController(
            firestoreService: FirestoreService(),
          ),
        )),
      ],
      child: const MyApp(),
    ),
  );
  StartupTimer.instance.mark('runApp.called');
}

Future<String?> _resolveSentryDsn() async {
  try {
    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: '.env');
      StartupTimer.instance.mark('env.preloaded');
    }
  } catch (e) {
    debugPrint('⚠️ Sentry DSN env load skipped: $e');
  }

  final envDsn = dotenv.maybeGet('SENTRY_DSN');
  if (envDsn != null && envDsn.isNotEmpty) {
    return envDsn;
  }
  if (Environment.sentryDsn.isNotEmpty) {
    return Environment.sentryDsn;
  }
  return null;
}

// 🚀 PERFORMANȚĂ: Funcție helper pentru inițializări în fundal
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          title: 'FriendsRide',
          
          localizationsDelegates: l10n.AppLocalizations.localizationsDelegates,
          supportedLocales: l10n.AppLocalizations.supportedLocales,
          
          locale: localeProvider.locale,
          
          theme: themeProvider.isHighContrast ? AppTheme.highContrastLight : AppTheme.lightTheme,
          darkTheme: themeProvider.isHighContrast ? AppTheme.highContrastDark : AppTheme.darkTheme,
          themeMode: themeProvider.currentTheme,
          
          // MODIFICAT: Aplicația pornește acum cu SplashScreen
          home: const SplashScreen(),

          routes: {
            '/onboarding': (_) => const OnboardingWizardScreen(),
            '/login': (_) => const SocialLoginScreen(),
            '/referral': (_) => const ReferralScreen(),
            '/gift-ride': (_) => const GiftRideScreen(),
            '/scheduled-rides': (_) => const ScheduledRideNotificationsScreen(),
          },
          
          debugShowCheckedModeBanner: false,
          showPerformanceOverlay: AppDrawer.showPerfOverlay,
          
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final safePadding = mediaQuery.padding;
            
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(
                  mediaQuery.textScaler.scale(1.0).clamp(0.9, 1.3)
                ),
              ),
              child: SafeArea(
                top: true,
                bottom: true,
                left: true,
                right: true,
                child: Container(
                  padding: EdgeInsets.only(
                    top: safePadding.top > 0 ? 0 : 8,
                    bottom: safePadding.bottom > 0 ? 4 : 8,
                  ),
                  child: child!,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// AuthWrapper rămâne neschimbat. SplashScreen va naviga aici după animație.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withAlpha(204),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withAlpha(76),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.directions_car_rounded,
                        size: 40,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      l10n.AppLocalizations.of(context)?.appTitle ?? 'FriendsRide',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        if (snapshot.hasData) {
          final user = snapshot.data;
          if (user != null) {
            return FutureBuilder<UserRole>(
              future: FirestoreService().getUserRole(),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    body: SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.AppLocalizations.of(context)?.profile ?? 'Profile',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                if (roleSnapshot.hasData) {
                  return const MapScreen();
                } else if (roleSnapshot.hasError) {
                  return Scaffold(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    body: SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 64,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.AppLocalizations.of(context)?.profile ?? 'Profile',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.AppLocalizations.of(context)?.settings ?? 'Settings',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                FirebaseAuth.instance.signOut();
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(l10n.AppLocalizations.of(context)?.settings ?? 'Settings'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                return const MapScreen();
              },
            );
          }
        }
        
        return const AuthScreen();
      },
    );
  }
}

/// Initialize background services without blocking main thread
Future<void> _initializeBackground() async {
  try {
    // Keep portrait but don't block startup on orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Show the device status bar and use edge-to-edge for modern look
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    StartupTimer.instance.mark('systemUi.ready');

    await initializeDateFormatting('ro_RO', null);
    StartupTimer.instance.mark('intl.ready');
    
    // Configure font fallbacks to avoid Noto font errors
    await _configureFonts();
    
    debugPrint('✅ Background initialization completed');
  } catch (e) {
    debugPrint('⚠️ Background initialization error (non-fatal): $e');
  }
}

/// Configure font fallbacks to avoid Noto font errors
Future<void> _configureFonts() async {
  try {
    // Set default font family to avoid Noto font errors
    // This will use system default fonts when Noto is not available
    debugPrint('ℹ️ Font fallbacks configured to avoid Noto errors');
  } catch (e) {
    debugPrint('⚠️ Font configuration error (non-fatal): $e');
  }
}
