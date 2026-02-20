/// 🔍 DEBUG LOGGER - Wrapper pentru debugPrint cu monitorizare
/// 
/// Acest utilitar înlocuiește debugPrint cu o versiune care monitorizează
/// automat mesajele pentru erori și warning-uri.
library;

import 'package:flutter/foundation.dart';
import 'package:friendsride_app/services/debug_console_monitor.dart';

/// Wrapper pentru debugPrint cu monitorizare automată
void debugLog(String message, {String? source, StackTrace? stackTrace}) {
  if (kDebugMode) {
    // Analizează mesajul pentru erori/warning-uri
    DebugConsoleMonitor().analyzeMessage(message, source: source, stackTrace: stackTrace);
    
    // Afișează mesajul normal
    debugPrint(message);
  }
}

/// Log pentru erori
void debugError(String message, {String? source, StackTrace? stackTrace}) {
  if (kDebugMode) {
    final errorMessage = '❌ [ERROR] $message';
    DebugConsoleMonitor().analyzeMessage(errorMessage, source: source, stackTrace: stackTrace);
    debugPrint(errorMessage);
  }
}

/// Log pentru warning-uri
void debugWarning(String message, {String? source}) {
  if (kDebugMode) {
    final warningMessage = '⚠️ [WARNING] $message';
    DebugConsoleMonitor().analyzeMessage(warningMessage, source: source);
    debugPrint(warningMessage);
  }
}

/// Log pentru info
void debugInfo(String message, {String? source}) {
  if (kDebugMode) {
    final infoMessage = '📋 [INFO] $message';
    DebugConsoleMonitor().analyzeMessage(infoMessage, source: source);
    debugPrint(infoMessage);
  }
}

/// Log pentru success
void debugSuccess(String message, {String? source}) {
  if (kDebugMode) {
    final successMessage = '✅ [SUCCESS] $message';
    DebugConsoleMonitor().analyzeMessage(successMessage, source: source);
    debugPrint(successMessage);
  }
}

