import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:friendsride_app/utils/logger.dart';

/// ✅ Helper pentru traduceri în modulul AI vocal (fără BuildContext)
class VoiceTranslations {
  static Future<String> _getCurrentLanguageCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('locale');
      return code ?? 'ro'; // Default română
    } catch (e) {
      Logger.error('Error getting language: $e', tag: 'VOICE_TRANSLATIONS', error: e);
      return 'ro'; // Default română
    }
  }
  
  /// Obține mesajul de salut
  static Future<String> getGreeting() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'Hello, where would you like to go?' : 'Salut, unde doriți să mergeți?';
  }
  
  /// Obține mesajul "Caut șoferi disponibili..."
  static Future<String> getSearchingDrivers() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'Searching for available drivers...' : 'Caut șoferi disponibili...';
  }
  
  /// Obține mesajul "Caut șoferi disponibili în zonă..."
  static Future<String> getSearchingDriversInArea() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'Searching for available drivers in your area...' : 'Caut șoferi disponibili în zonă...';
  }
  
  /// Obține mesajul "Am găsit un șofer disponibil la X minute distanță"
  static Future<String> getDriverFound(int minutes) async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' 
        ? 'Found an available driver $minutes minutes away.'
        : 'Am găsit un șofer disponibil la $minutes minute distanță.';
  }
  
  /// Obține mesajul "Nu am găsit șoferi disponibili"
  static Future<String> getNoDriversAvailable() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Sorry, but I couldn\'t find any available drivers in your area. Please try again later.'
        : 'Îmi pare rău, dar nu am găsit șoferi disponibili în zona dumneavoastră. Te rugăm să revii mai târziu.';
  }
  
  /// Obține mesajul "Perfect! Am rezolvat totul..."
  static Future<String> getEverythingResolved(String driverName, int etaMinutes, double price) async {
    final lang = await _getCurrentLanguageCode();
    final priceRounded = price.toStringAsFixed(0);
    return lang == 'en'
        ? 'Perfect! I\'ve resolved everything. $driverName is arriving in $etaMinutes minutes. The ride price is $priceRounded lei. Thank you for using FriendsRide!'
        : 'Perfect! Am rezolvat totul. $driverName vine în $etaMinutes minute. Prețul cursei este de $priceRounded lei. Vă mulțumim că ați folosit FriendsRide!';
  }
  
  /// Obține mesajul "Perfect! Șoferul a fost notificat..."
  static Future<String> getDriverNotified() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Perfect! The driver has been notified. Have a pleasant trip!'
        : 'Perfect! Șoferul a fost notificat. Călătorie plăcută!';
  }
  
  /// Obține mesajul "Îmi pare rău, nu am putut găsi adresa..."
  static Future<String> getAddressNotFound(String address) async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Sorry, I couldn\'t find the address "$address". Please specify a clearer address or a known location.'
        : 'Îmi pare rău, nu am putut găsi adresa "$address". Vă rog să specificați o adresă mai clară sau un loc cunoscut.';
  }
  
  /// Obține mesajul "Perfect! Completez adresele..."
  static Future<String> getCompletingAddresses() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Perfect! I\'m completing the addresses and sending the request to drivers.'
        : 'Perfect! Completez adresele și trimit solicitarea către șoferi.';
  }
  
  /// Obține mesajul "Perfect! Am înțeles destinația..."
  static Future<String> getDestinationUnderstood() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Perfect! I understood the destination. I\'m processing everything automatically - detecting location, searching for drivers and making the reservation.'
        : 'Perfect! Am înțeles destinația. Procesez totul automat - detectez locația, caut șoferi și fac rezervarea.';
  }
  
  /// Obține mesajul "Vă rog să îmi spuneți unde doriți să mergeți"
  static Future<String> getPleaseSpecifyDestination() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Please tell me where you would like to go.'
        : 'Vă rog să îmi spuneți unde doriți să mergeți.';
  }
  
  /// Obține mesajul "Nu am înțeles. Puteți să repetați destinația?"
  static Future<String> getDidNotUnderstandRepeatDestination() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'I didn\'t understand. Can you repeat the destination?'
        : 'Nu am înțeles. Puteți să repetați destinația?';
  }
  
  /// Obține mesajul "Înțeleg că nu confirmați..."
  static Future<String> getNotConfirmedPleaseSpecify() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'I understand you don\'t confirm. Please specify again where you would like to go.'
        : 'Înțeleg că nu confirmați. Vă rog să specificați din nou unde doriți să mergeți.';
  }
  
  /// Obține mesajul pentru confirmare
  static Future<String> getConfirmationMessage(String? languageCode) async {
    final lang = languageCode ?? await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Perfect! I understood the confirmation. Continuing with driver search...'
        : 'Perfect! Am înțeles confirmarea. Continuă cu căutarea șoferilor...';
  }
  
  /// Obține mesajul pentru clarificare
  static Future<String> getClarificationQuestion([String? languageCode]) async {
    final lang = languageCode ?? await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'I didn\'t understand the response. Please answer "yes" to continue or "no" to specify the destination again.'
        : 'Nu am înțeles răspunsul. Vă rog să răspundeți cu "da" pentru a continua sau "nu" pentru a specifica din nou destinația.';
  }
  
  /// Obține mesajul "Excelent! Trimit solicitarea către șoferi..."
  static Future<String> getSendingRequestToDrivers() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Excellent! Sending the request to drivers...'
        : 'Excelent! Trimit solicitarea către șoferi...';
  }
  
  /// Obține mesajul "Excelent! Solicitarea a fost trimisă..."
  static Future<String> getRequestSentToDrivers() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Excellent! The request has been sent to drivers. We are waiting for a response...'
        : 'Excelent! Solicitarea a fost trimisă către șoferi. Așteptăm răspunsul...';
  }
  
  /// Obține mesajul pentru prețul cursei
  static Future<String> getRidePrice(double price) async {
    final lang = await _getCurrentLanguageCode();
    final priceRounded = price.toStringAsFixed(2);
    return lang == 'en'
        ? 'The ride price is $priceRounded lei.'
        : 'Prețul cursei este de $priceRounded lei.';
  }
  
  /// Obține mesajul "Cursa a început. Călătorie plăcută!"
  static Future<String> getRideStartedEnjoyTrip() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'The ride has started. Have a pleasant trip!'
        : 'Cursa a început. Călătorie plăcută!';
  }
  
  /// Obține mesajul pentru șofer acceptat
  static Future<String> getDriverAcceptedMessage(String driverName, String car, String carColor, String plate, int eta) async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Excellent news! $driverName with $car $carColor $plate has accepted the ride and will arrive in approximately $eta minutes.'
        : 'Veste excelentă! $driverName cu $car $carColor $plate a acceptat cursa și va ajunge în aproximativ $eta minute.';
  }
  
  /// Obține mesajul "Detectez locația curentă..."
  static Future<String> getDetectingCurrentLocation() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Detecting your current location...'
        : 'Detectez locația curentă...';
  }
  
  /// Obține mesajul "Calculez prețul cursei..."
  static Future<String> getCalculatingPrice() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Calculating the ride price...'
        : 'Calculez prețul cursei...';
  }
  
  /// Obține mesajul "Verific adresa destinației..."
  static Future<String> getVerifyingDestination() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Verifying the destination address...'
        : 'Verific adresa destinației...';
  }
  
  /// Obține mesajul "Procesez informațiile..."
  static Future<String> getProcessingInformation() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Processing the information...'
        : 'Procesez informațiile...';
  }
  
  /// Obține mesajul pentru confirmarea destinației cu preț
  static Future<String> getDestinationWithPrice(String destination, String priceString) async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'I understand! You want to go to $destination. The ride costs approximately $priceString. Do you confirm?'
        : 'Am înțeles! Doriți să mergeți la $destination. Cursa costă aproximativ $priceString. Confirmați?';
  }
  
  /// Obține mesajul pentru confirmarea pickup-ului
  static Future<String> getPickupConfirmation(String pickup) async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Perfect! I understood that pickup is from $pickup. Searching for available drivers...'
        : 'Perfect! Am înțeles că preluarea se face de la $pickup. Caut șoferi disponibili...';
  }
  
  /// Obține mesajul pentru confirmarea generală
  static Future<String> getGeneralConfirmation() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Perfect! I understood the confirmation. Continuing with driver search...'
        : 'Perfect! Am înțeles confirmarea. Continuă cu căutarea șoferilor...';
  }
  
  /// Obține mesajul pentru confirmarea finală a cursei
  static Future<String> getFinalRideConfirmation() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Perfect! Sending the request to drivers...'
        : 'Perfect! Trimit cererea către șoferi...';
  }
  
  /// Obține mesajul pentru eroare "Nu am putut..."
  static Future<String> getErrorCouldNot(String action) async {
    final lang = await _getCurrentLanguageCode();
    final actionEn = lang == 'en' ? action : action; // Poate fi tradus mai târziu
    return lang == 'en'
        ? 'I couldn\'t $actionEn. Please try again.'
        : 'Nu am putut $action. Vă rugăm să încercați din nou.';
  }
  
  /// Obține mesajul pentru eroare "Nu am putut găsi șoferi"
  static Future<String> getErrorCouldNotFindDrivers() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'I couldn\'t find available drivers at this time. We will try again immediately.'
        : 'Nu am putut găsi șoferi disponibili în acest moment. Încercăm din nou imediat.';
  }
}

