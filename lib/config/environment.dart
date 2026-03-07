// IMPLEMENTARE ENVIRONMENT CONFIGURATION - FIX SECURITY VULNERABILITIES
import 'package:flutter/foundation.dart';
import 'package:friendsride_app/utils/logger.dart';

class Environment {
  // OpenAI Configuration
  static const String openaiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: 'sk-PLACEHOLDER_KEY_FOR_DEVELOPMENT',
  );
  
  // Gemini AI Configuration
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'REPLACE_WITH_YOUR_GEMINI_API_KEY', // Set via --dart-define=GEMINI_API_KEY=AIza...
  );
  
  // Mapbox Configuration
  // ✅ SECURITY FIX: Tokens din environment variables
  static const String mapboxPublicToken = String.fromEnvironment(
    'MAPBOX_PUBLIC_TOKEN',
    defaultValue: 'pk.REPLACE_WITH_YOUR_MAPBOX_PUBLIC_TOKEN', // Set via --dart-define=MAPBOX_PUBLIC_TOKEN=pk.xxx
  );
  
  static const String mapboxSecretToken = String.fromEnvironment(
    'MAPBOX_SECRET_TOKEN',
    defaultValue: 'sk.REPLACE_WITH_YOUR_MAPBOX_SECRET_TOKEN', // Set via --dart-define=MAPBOX_SECRET_TOKEN=sk.xxx
  );
  
  // Firebase Configuration
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'REPLACE_WITH_YOUR_FIREBASE_API_KEY', // Set via --dart-define=FIREBASE_API_KEY=AIza...
  );
  
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'friendsride-v2',
  );
  
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: 'https://public-example-key@o4500000000000000.ingest.sentry.io/4500000000000000',
  );
  
  // Validation Methods
  static void validateTokens() {
    // ✅ FIX: Validare mai flexibilă pentru development
    if (isDevelopment) {
      // În development, doar Mapbox trebuie să fie valid
      if (mapboxPublicToken.isEmpty || !mapboxPublicToken.startsWith('pk.eyJ1')) {
        Logger.warning('DEVELOPMENT MODE: Mapbox token invalid - maps will not work!');
        Logger.debug('To fix: Replace mapboxPublicToken with your real Mapbox token');
        Logger.debug('Get token from: https://account.mapbox.com/access-tokens/');
      } else {
        Logger.info('Development mode: Mapbox token configured correctly');
      }
      
      // Pentru OpenAI și Firebase, doar warning în development
      if (openaiApiKey.contains('PLACEHOLDER')) {
        Logger.warning('DEVELOPMENT MODE: OpenAI API key is placeholder');
        Logger.debug('Set OPENAI_API_KEY for full functionality');
      }
      
      // Validare pentru Gemini în development
      if (geminiApiKey.contains('PLACEHOLDER') || geminiApiKey.isEmpty) {
        Logger.warning('DEVELOPMENT MODE: Gemini API key is placeholder');
        Logger.debug('Set GEMINI_API_KEY for AI voice functionality');
      } else {
        Logger.info('Development mode: Gemini API key configured correctly');
      }
      
      if (firebaseApiKey.contains('PLACEHOLDER')) {
        Logger.warning('DEVELOPMENT MODE: Firebase API key is placeholder');
        Logger.debug('Set FIREBASE_API_KEY for full functionality');
      }
      
      return; // Nu arunca excepție în development
    }
    
    // În production, validează strict
    final missingTokens = <String>[];
    
    if (openaiApiKey.isEmpty || openaiApiKey.contains('PLACEHOLDER')) {
      missingTokens.add('OPENAI_API_KEY');
    }
    
    if (geminiApiKey.isEmpty || geminiApiKey.contains('PLACEHOLDER')) {
      missingTokens.add('GEMINI_API_KEY');
    }
    
    if (mapboxPublicToken.isEmpty || !mapboxPublicToken.startsWith('pk.eyJ1')) {
      missingTokens.add('MAPBOX_PUBLIC_TOKEN');
    }
    
    if (mapboxSecretToken.isEmpty || !mapboxSecretToken.startsWith('sk.eyJ1')) {
      missingTokens.add('MAPBOX_SECRET_TOKEN');
    }
    
    if (firebaseApiKey.isEmpty || firebaseApiKey.contains('PLACEHOLDER')) {
      missingTokens.add('FIREBASE_API_KEY');
    }
    
    if (firebaseProjectId.isEmpty) {
      missingTokens.add('FIREBASE_PROJECT_ID');
    }
    
    if (missingTokens.isNotEmpty) {
      throw Exception('''
🚨 MISSING ENVIRONMENT VARIABLES!

Următoarele variabile de mediu lipsesc:
${missingTokens.map((token) => '   - $token').join('\n')}

CONFIGURARE PENTRU DEVELOPMENT:
flutter run --dart-define=OPENAI_API_KEY=your_key_here --dart-define=GEMINI_API_KEY=your_key_here --dart-define=FIREBASE_API_KEY=your_key_here --dart-define=MAPBOX_PUBLIC_TOKEN=your_token_here --dart-define=MAPBOX_SECRET_TOKEN=your_secret_here

CONFIGURARE PENTRU PRODUCTION:
Adaugă în build.gradle sau xcconfig:
${missingTokens.map((token) => '$token=your_value_here').join('\n')}

⚠️  Aplicația nu va porni fără aceste variabile configurate!
      ''');
    }
  }
  
  // Environment Detection
  static bool get isDevelopment => const bool.fromEnvironment('dart.vm.product') == false;
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product') == true;
  static bool get isTest => const bool.fromEnvironment('dart.vm.product') == false && 
                           const bool.fromEnvironment('dart.vm.checkAssertions') == true;
  
  // Configuration Status
  static bool get isFullyConfigured {
    try {
      validateTokens();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Debug Information (only in development)
  static void printConfigurationStatus() {
    if (!isDevelopment) return;
    
    Logger.debug('');
  }
}