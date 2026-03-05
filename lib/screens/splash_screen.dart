import 'dart:async';
import 'package:flutter/material.dart';
// Navigăm direct către ecranele finale pentru a evita intermediarul "profil"
import 'package:friendsride_app/screens/auth_screen.dart';
import 'package:friendsride_app/screens/map_screen.dart';
import 'package:provider/provider.dart';
import 'package:friendsride_app/services/app_initializer.dart';
import 'package:friendsride_app/widgets/romanian_flag.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:friendsride_app/services/startup_timer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:friendsride_app/services/firestore_service.dart';
import 'package:friendsride_app/utils/logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _positionAnimation;
  // ignore: unused_field, prefer_final_fields
  bool _navigated = false;
  bool _minVisibleElapsed = false;
  static const Duration _minVisibleDuration = Duration(milliseconds: 500);

  // Eliminated artificial minimum splash duration for faster startup
  // Removed usage; kept for future toggling
  // ignore: unused_field
  final Duration _minSplashDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      // Animația vizuală redusă pentru startup mai rapid
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _positionAnimation = Tween<Offset>(
      begin: const Offset(-0.8, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.25, 1, 0.5, 1),
      ),
    );

    // Pornim procesul de inițializare și navigație
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    Logger.info('initializeApp start', tag: 'SPLASH');
    StartupTimer.instance.mark('splash.init');
    // 🚀 PERFORMANȚĂ: Pornim animația vizuală imediat
    _controller.forward();

    // Trigger background initialization via AppInitializer
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AppInitializer>().initialize();
        StartupTimer.instance.mark('initializer.triggered');
      });
    } catch (_) {}
    
    // Înlătură splash-ul nativ imediat după primul frame pentru a afișa splash-ul Flutter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        FlutterNativeSplash.remove();
        StartupTimer.instance.mark('nativeSplash.removed');
      } catch (_) {}
    });

    // Menține splash-ul Flutter vizibil cel puțin 800ms pentru tranziție lină
    Future.delayed(_minVisibleDuration, () {
      if (!mounted) return;
      setState(() {
        _minVisibleElapsed = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 54, 130, 243),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: SlideTransition(
                  position: _positionAnimation,
                  child: CustomPaint(
                    painter: LogoPainter(
                      progress: _progressAnimation.value,
                    ),
                  ),
                ),
              ),
              // Live status watcher: when ready -> navigate
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Consumer<AppInitializer>(
                      builder: (context, init, _) {
                        if (init.status == AppStatus.ready && _minVisibleElapsed && !_navigated) {
                          WidgetsBinding.instance.addPostFrameCallback((_) async {
                            if (!context.mounted || _navigated) return;
                            // Verifică starea de autentificare; dacă e logat, mergem direct la MapScreen
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              if (!context.mounted) return;
                              _navigated = true;
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => const AuthScreen()),
                              );
                              return;
                            }

                            // Opțional: preîncărcăm rolul ca să evităm flicker ulterior (non-blocant pentru UI)
                            try { await FirestoreService().getUserRole(); } catch (_) {}

                            if (!context.mounted) return;
                            _navigated = true;
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const MapScreen()),
                            );
                          });
                        }
                        if (init.status == AppStatus.error) {
                          return const Text(
                            'A apărut o eroare la pornire. Verifică internetul.',
                            style: TextStyle(color: Colors.white),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Fabricat în România',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'DancingScript',
                      ),
                    ),
                    const SizedBox(width: 8),
                    const RomanianFlag(height: 18),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Clasa LogoPainter rămâne neschimbată
class LogoPainter extends CustomPainter {
  final double progress;

  LogoPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Typewriter/reveal effect for 'FriendsRide'
    const String fullText = 'FriendsRide';
    final int totalChars = fullText.length;
    final int visibleChars = (progress.clamp(0.0, 1.0) * totalChars).ceil().clamp(0, totalChars);
    final String visibleText = fullText.substring(0, visibleChars);

    final TextStyle textStyle = const TextStyle(
      fontFamily: 'DancingScript',
      fontWeight: FontWeight.w700,
      fontSize: 70,
      color: Colors.white,
    );

    final TextSpan textSpan = TextSpan(text: visibleText, style: textStyle);
    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    // Center the text on the canvas
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final Offset drawOffset = Offset(-textPainter.width / 2, -textPainter.height / 2);
    textPainter.paint(canvas, drawOffset);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LogoPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
