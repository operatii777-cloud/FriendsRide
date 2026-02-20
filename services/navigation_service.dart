import 'dart:async';
import 'package:flutter/foundation.dart';



// O structură simplă pentru a ține o instrucțiune vocală
class VoiceInstruction {
  final String announcement; // Textul care trebuie rostit
  final double distanceAlongGeometry; // Distanța în metri de la începutul pasului unde trebuie rostit

  VoiceInstruction({required this.announcement, required this.distanceAlongGeometry});
}

// Model pentru instrucțiuni de navigație
class NavigationStep {
  final String instruction;
  final double distance; // în metri
  final double duration; // în secunde
  final Map<String, dynamic> location;
  final String? modifier; // left, right, straight, etc.
  final String? type; // turn, arrive, depart, etc.
  final List<List<double>>? geometry; // coordonatele polyline pentru acest pas
  final List<VoiceInstruction> voiceInstructions; // Lista cu instrucțiuni vocale detaliate

  NavigationStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.location,
    this.modifier,
    this.type,
    this.geometry,
    this.voiceInstructions = const [], // Valoare goală implicită
  });
}

class NavigationService {
  Future<Location> getCurrentLocation() async {
    try {
      // Simulate getting current location
      await Future.delayed(Duration(milliseconds: 500));
      
      return Location(
        latitude: 44.4268,
        longitude: 26.1025,
        address: 'Bucharest, Romania',
      );
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  Future<Route> getRoute({
    String? from,
    String? to,
  }) async {
    try {
      // Simulate route calculation
      await Future.delayed(Duration(seconds: 1));
      
      return Route(
        duration: '15 minutes',
        distance: '5.2 km',
        origin: from ?? 'Current location',
        destination: to ?? 'Unknown destination',
      );
    } catch (e) {
      throw Exception('Failed to calculate route: $e');
    }
  }

  Future<ETA> calculateETA({
    required String to,
  }) async {
    try {
      // Simulate ETA calculation
      await Future.delayed(Duration(milliseconds: 800));
      
      return ETA(
        duration: '12 minutes',
        destination: to,
      );
    } catch (e) {
      throw Exception('Failed to calculate ETA: $e');
    }
  }

  Future<TrafficInfo> getTrafficConditions() async {
    try {
      // Simulate traffic info retrieval
      await Future.delayed(Duration(milliseconds: 600));
      
      return TrafficInfo(
        description: 'Light traffic conditions',
        severity: 'low',
      );
    } catch (e) {
      throw Exception('Failed to get traffic conditions: $e');
    }
  }

  // Callback properties for navigation events
  Function(Map<String, dynamic>)? onNavigationUpdate;
  Function(String)? onArrival;
  Function(Map<String, dynamic>)? onRouteDeviation;

  // Navigation state variables
  List<NavigationStep> _currentNavigationSteps = [];
  Map<String, dynamic>? _routeSummary;
  int _currentStepIndex = 0;
  bool _isNavigating = false;
  DateTime? _navigationStartTime;
  Timer? _navigationTimer;

  /// Dispose resources and clear callbacks
  void dispose() {
    // Stop navigation if active
    if (_isNavigating) {
      _stopNavigation();
    }
    
    // Cancel navigation timer
    _navigationTimer?.cancel();
    
    // Clean up resources and callbacks
    onNavigationUpdate = null;
    onArrival = null;
    onRouteDeviation = null;
  }

  /// Parse Mapbox route data
  List<NavigationStep> parseMapboxRoute(Map<String, dynamic> routeData) {
    try {
      final List<NavigationStep> steps = [];
      
      // Extract route data from Mapbox response
      final routes = routeData['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        debugPrint('No routes found in Mapbox response');
        return steps;
      }
      
      final route = routes.first as Map<String, dynamic>;
      final legs = route['legs'] as List<dynamic>?;
      if (legs == null || legs.isEmpty) {
        debugPrint('No legs found in route');
        return steps;
      }
      
      final leg = legs.first as Map<String, dynamic>;
      final stepsData = leg['steps'] as List<dynamic>?;
      if (stepsData == null) {
        debugPrint('No steps found in leg');
        return steps;
      }
      
      // Parse each navigation step
      for (int i = 0; i < stepsData.length; i++) {
        final stepData = stepsData[i] as Map<String, dynamic>;
        
        // Extract basic step information
        final instruction = stepData['maneuver']?['instruction'] ?? 'Continue';
        final distance = (stepData['distance'] ?? 0.0).toDouble();
        final duration = (stepData['duration'] ?? 0.0).toDouble();
        
        // Extract location data
        final location = {
          'latitude': stepData['maneuver']?['location']?[1] ?? 0.0,
          'longitude': stepData['maneuver']?['location']?[0] ?? 0.0,
        };
        
        // Extract maneuver details
        final modifier = stepData['maneuver']?['modifier'];
        final type = stepData['maneuver']?['type'];
        
        // Extract geometry for polyline
        final geometry = stepData['geometry'] as List<dynamic>?;
        List<List<double>>? parsedGeometry;
        if (geometry != null) {
          parsedGeometry = geometry.map((coord) {
            if (coord is List) {
              return coord.map((val) => (val as num).toDouble()).toList();
            }
            return <double>[];
          }).where((coord) => coord.length >= 2).toList();
        }
        
        // Create voice instructions
        final voiceInstructions = <VoiceInstruction>[];
        if (distance > 100) { // Only add voice instructions for significant steps
          voiceInstructions.add(VoiceInstruction(
            announcement: instruction,
            distanceAlongGeometry: distance / 2, // Announce at middle of step
          ));
        }
        
        // Create NavigationStep
        final step = NavigationStep(
          instruction: instruction,
          distance: distance,
          duration: duration,
          location: location,
          modifier: modifier,
          type: type,
          geometry: parsedGeometry,
          voiceInstructions: voiceInstructions,
        );
        
        steps.add(step);
      }
      
      debugPrint('✅ Parsed ${steps.length} navigation steps from Mapbox route');
      return steps;
      
    } catch (e) {
      debugPrint('❌ Error parsing Mapbox route: $e');
      return [];
    }
  }

  /// Set navigation steps
  void setNavigationSteps(List<NavigationStep> steps) {
    try {
      if (steps.isEmpty) {
        debugPrint('⚠️ No navigation steps to set');
        return;
      }
      
      // Store current navigation steps
      _currentNavigationSteps = List<NavigationStep>.from(steps);
      
      // Calculate total route statistics
      double totalDistance = 0.0;
      double totalDuration = 0.0;
      
      for (final step in steps) {
        totalDistance += step.distance;
        totalDuration += step.duration;
      }
      
      // Update route summary
      _routeSummary = {
        'totalSteps': steps.length,
        'totalDistance': totalDistance,
        'totalDuration': totalDuration,
        'estimatedArrival': DateTime.now().add(Duration(seconds: totalDuration.round())),
      };
      
      // Set current step index
      _currentStepIndex = 0;
      
      // Notify listeners about navigation steps update
      if (onNavigationUpdate != null) {
        onNavigationUpdate!({
          'action': 'steps_set',
          'totalSteps': steps.length,
          'totalDistance': totalDistance,
          'totalDuration': totalDuration,
          'currentStep': _currentStepIndex,
          'currentInstruction': steps.isNotEmpty ? steps.first.instruction : 'No instruction',
        });
      }
      
      debugPrint('✅ Navigation steps set: ${steps.length} steps, ${(totalDistance / 1000).toStringAsFixed(2)}km, ${(totalDuration / 60).toStringAsFixed(1)}min');
      
    } catch (e) {
      debugPrint('❌ Error setting navigation steps: $e');
    }
  }

  /// Start navigation with route data
  Future<void> startNavigation(Map<String, dynamic> routeData) async {
    try {
      debugPrint('🚀 Starting navigation with route data...');
      
      // Parse route data to get navigation steps
      final steps = parseMapboxRoute(routeData);
      if (steps.isEmpty) {
        throw Exception('No valid navigation steps found in route data');
      }
      
      // Set navigation steps
      setNavigationSteps(steps);
      
      // Initialize navigation state
      _isNavigating = true;
      _navigationStartTime = DateTime.now();
      _currentStepIndex = 0;
      
      // Start navigation monitoring
      _startNavigationMonitoring();
      
      // Notify listeners about navigation start
      if (onNavigationUpdate != null) {
        onNavigationUpdate!({
          'action': 'navigation_started',
          'totalSteps': steps.length,
          'currentStep': _currentStepIndex,
          'currentInstruction': steps.first.instruction,
          'startTime': _navigationStartTime!.toIso8601String(),
        });
      }
      
      debugPrint('✅ Navigation started successfully with ${steps.length} steps');
      
    } catch (e) {
      debugPrint('❌ Error starting navigation: $e');
      _isNavigating = false;
      rethrow;
    }
  }

  /// Start navigation monitoring timer
  void _startNavigationMonitoring() {
    _navigationTimer?.cancel();
    _navigationTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!_isNavigating || _currentNavigationSteps.isEmpty) {
        timer.cancel();
        return;
      }
      
      _updateNavigationProgress();
    });
  }

  /// Update navigation progress and check for step completion
  void _updateNavigationProgress() {
    try {
      if (_currentStepIndex >= _currentNavigationSteps.length) {
        _completeNavigation();
        return;
      }
      
      final currentStep = _currentNavigationSteps[_currentStepIndex];
      
      // Simulate progress update (in real implementation, this would check actual GPS position)
      if (onNavigationUpdate != null) {
        onNavigationUpdate!({
          'action': 'progress_update',
          'currentStep': _currentStepIndex + 1,
          'totalSteps': _currentNavigationSteps.length,
          'currentInstruction': currentStep.instruction,
          'distanceRemaining': currentStep.distance,
          'timeRemaining': currentStep.duration,
        });
      }
      
      // Check if current step is completed (simplified logic)
      if (_shouldAdvanceToNextStep()) {
        _advanceToNextStep();
      }
      
    } catch (e) {
      debugPrint('❌ Error updating navigation progress: $e');
    }
  }

  /// Check if should advance to next step (simplified logic)
  bool _shouldAdvanceToNextStep() {
    // In real implementation, this would check GPS position and distance to step completion
    // For now, use a simple time-based approach
    if (_navigationStartTime == null) return false;
    
    final elapsed = DateTime.now().difference(_navigationStartTime!).inSeconds;
    final currentStep = _currentNavigationSteps[_currentStepIndex];
    
    return elapsed >= currentStep.duration;
  }

  /// Advance to next navigation step
  void _advanceToNextStep() {
    _currentStepIndex++;
    
    if (_currentStepIndex >= _currentNavigationSteps.length) {
      _completeNavigation();
      return;
    }
    
    final nextStep = _currentNavigationSteps[_currentStepIndex];
    
    // Notify about step advancement
    if (onNavigationUpdate != null) {
      onNavigationUpdate!({
        'action': 'step_advanced',
        'currentStep': _currentStepIndex + 1,
        'totalSteps': _currentNavigationSteps.length,
        'currentInstruction': nextStep.instruction,
        'distanceRemaining': nextStep.distance,
        'timeRemaining': nextStep.duration,
      });
    }
    
    debugPrint('🔄 Advanced to step ${_currentStepIndex + 1}: ${nextStep.instruction}');
  }

  /// Complete navigation journey
  void _completeNavigation() {
    _isNavigating = false;
    _navigationTimer?.cancel();
    
    if (onArrival != null) {
      onArrival!('Destination reached');
    }
    
    if (onNavigationUpdate != null) {
      onNavigationUpdate!({
        'action': 'navigation_completed',
        'totalSteps': _currentNavigationSteps.length,
        'finalStep': _currentStepIndex,
        'completionTime': DateTime.now().toIso8601String(),
      });
    }
    
    debugPrint('🎯 Navigation completed successfully');
  }

  /// Stop navigation
  void _stopNavigation() {
    _isNavigating = false;
    _navigationTimer?.cancel();
    
    if (onNavigationUpdate != null) {
      onNavigationUpdate!({
        'action': 'navigation_stopped',
        'currentStep': _currentStepIndex,
        'totalSteps': _currentNavigationSteps.length,
        'stopTime': DateTime.now().toIso8601String(),
      });
    }
    
    debugPrint('⏹️ Navigation stopped');
  }

  /// Get current navigation status
  Map<String, dynamic> getNavigationStatus() {
    return {
      'isNavigating': _isNavigating,
      'currentStep': _currentStepIndex + 1,
      'totalSteps': _currentNavigationSteps.length,
      'routeSummary': _routeSummary,
      'startTime': _navigationStartTime?.toIso8601String(),
      'currentInstruction': _currentNavigationSteps.isNotEmpty && _currentStepIndex < _currentNavigationSteps.length
          ? _currentNavigationSteps[_currentStepIndex].instruction
          : 'No instruction',
    };
  }
}

class Route {
  final String duration;
  final String distance;
  final String origin;
  final String destination;

  Route({
    required this.duration,
    required this.distance,
    required this.origin,
    required this.destination,
  });
}

class ETA {
  final String duration;
  final String destination;

  ETA({
    required this.duration,
    required this.destination,
  });
}

class TrafficInfo {
  final String description;
  final String severity;

  TrafficInfo({
    required this.description,
    required this.severity,
  });
}

class Location {
  final double latitude;
  final double longitude;
  final String? address;

  Location({
    required this.latitude,
    required this.longitude,
    this.address,
  });
}