/// Model pentru preferințe de cursă (Uber-like)
class RidePreferences {
  final bool? preferMusic; // Preferă muzică
  final String? musicPreference; // Tip de muzică preferat
  final bool? preferConversation; // Preferă conversație
  final bool? preferQuiet; // Preferă liniște
  final String? temperaturePreference; // Temperatură preferată (cold, normal, warm)
  final bool? preferWindowOpen; // Preferă geam deschis
  final String? routePreference; // Preferință rută (fastest, scenic, avoid_tolls)
  final bool? preferChildSeat; // Preferă scaun pentru copii
  final String? accessibilityNeeds; // Nevoi de accesibilitate

  // ── Câmpuri noi ────────────────────────────────────────────────────────────
  /// Tipul de vehicul preferat: 'sedan', 'suv', 'van', 'any' (implicit)
  final String? preferredVehicle;

  /// Preferință AC: 'on', 'off', 'any' (implicit)
  final String? acPreference;

  /// Note suplimentare pentru șofer (max 200 caractere recomandat)
  final String? notes;

  const RidePreferences({
    this.preferMusic,
    this.musicPreference,
    this.preferConversation,
    this.preferQuiet,
    this.temperaturePreference,
    this.preferWindowOpen,
    this.routePreference,
    this.preferChildSeat,
    this.accessibilityNeeds,
    this.preferredVehicle,
    this.acPreference,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      if (preferMusic != null) 'preferMusic': preferMusic,
      if (musicPreference != null) 'musicPreference': musicPreference,
      if (preferConversation != null) 'preferConversation': preferConversation,
      if (preferQuiet != null) 'preferQuiet': preferQuiet,
      if (temperaturePreference != null) 'temperaturePreference': temperaturePreference,
      if (preferWindowOpen != null) 'preferWindowOpen': preferWindowOpen,
      if (routePreference != null) 'routePreference': routePreference,
      if (preferChildSeat != null) 'preferChildSeat': preferChildSeat,
      if (accessibilityNeeds != null) 'accessibilityNeeds': accessibilityNeeds,
      if (preferredVehicle != null) 'preferredVehicle': preferredVehicle,
      if (acPreference != null) 'acPreference': acPreference,
      if (notes != null) 'notes': notes,
    };
  }

  factory RidePreferences.fromMap(Map<String, dynamic> map) {
    return RidePreferences(
      preferMusic: map['preferMusic'] as bool?,
      musicPreference: map['musicPreference'] as String?,
      preferConversation: map['preferConversation'] as bool?,
      preferQuiet: map['preferQuiet'] as bool?,
      temperaturePreference: map['temperaturePreference'] as String?,
      preferWindowOpen: map['preferWindowOpen'] as bool?,
      routePreference: map['routePreference'] as String?,
      preferChildSeat: map['preferChildSeat'] as bool?,
      accessibilityNeeds: map['accessibilityNeeds'] as String?,
      preferredVehicle: map['preferredVehicle'] as String?,
      acPreference: map['acPreference'] as String?,
      notes: map['notes'] as String?,
    );
  }

  RidePreferences copyWith({
    bool? preferMusic,
    String? musicPreference,
    bool? preferConversation,
    bool? preferQuiet,
    String? temperaturePreference,
    bool? preferWindowOpen,
    String? routePreference,
    bool? preferChildSeat,
    String? accessibilityNeeds,
    String? preferredVehicle,
    String? acPreference,
    String? notes,
  }) {
    return RidePreferences(
      preferMusic: preferMusic ?? this.preferMusic,
      musicPreference: musicPreference ?? this.musicPreference,
      preferConversation: preferConversation ?? this.preferConversation,
      preferQuiet: preferQuiet ?? this.preferQuiet,
      temperaturePreference: temperaturePreference ?? this.temperaturePreference,
      preferWindowOpen: preferWindowOpen ?? this.preferWindowOpen,
      routePreference: routePreference ?? this.routePreference,
      preferChildSeat: preferChildSeat ?? this.preferChildSeat,
      accessibilityNeeds: accessibilityNeeds ?? this.accessibilityNeeds,
      preferredVehicle: preferredVehicle ?? this.preferredVehicle,
      acPreference: acPreference ?? this.acPreference,
      notes: notes ?? this.notes,
    );
  }
}

