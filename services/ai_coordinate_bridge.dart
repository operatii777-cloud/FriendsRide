import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import '../utils/coordinate_helpers.dart';
import '../utils/deprecated_apis_fix.dart';

/// AI Coordinate Bridge Service
/// 
/// This service acts as a bridge between the AI system and the map rendering system,
/// handling all coordinate type conversions and ensuring compatibility.
/// 
/// The AI system uses Point objects internally, while the map system uses
/// Map types for various APIs. This bridge provides seamless
/// conversion between these types without affecting AI functionality.
class AICoordinateBridge {
  static final AICoordinateBridge _instance = AICoordinateBridge._internal();
  factory AICoordinateBridge() => _instance;
  AICoordinateBridge._internal();

  // ===== AI SYSTEM INTERFACE (Point-based) =====
  
  /// AI System: Get current device location as Point
  /// Used by AI services that need current location
  Future<Point?> getCurrentLocationAsPoint() async {
    try {
      final position = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: DeprecatedAPIsFix.createLocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        ),
      );
      
      return CoordinateHelpers.geolocatorPositionToPoint(position);
    } catch (e) {
      return null;
    }
  }
  
  /// AI System: Convert address to Point coordinates
  /// Used by AI services that work with addresses
  Future<Point?> addressToPoint(String address) async {
    try {
      // This would integrate with a geocoding service
      // For now, return null as placeholder
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// AI System: Convert Point to human-readable address
  /// Used by AI services that need to display location information
  Future<String?> pointToAddress(Point point) async {
    try {
      // This would integrate with a reverse geocoding service
      // For now, return coordinates as string
      return '${point.coordinates.lat.toDouble().toStringAsFixed(6)}, '
             '${point.coordinates.lng.toDouble().toStringAsFixed(6)}';
    } catch (e) {
      return null;
    }
  }
  
  /// AI System: Calculate route between multiple points
  /// Used by AI services that need routing information
  Future<Map<String, dynamic>?> calculateRoute(List<Point> waypoints) async {
    try {
      // This would integrate with a routing service
      // For now, return basic route information
      if (waypoints.length < 2) return null;
      
      final start = waypoints.first;
      final end = waypoints.last;
      final distance = CoordinateHelpers.calculateDistance(start, end);
      
      return {
        'distance': distance,
        'duration': distance / 13.89, // Assuming 50 km/h average speed
        'waypoints': waypoints.map((p) => CoordinateHelpers.pointToMap(p)).toList(),
      };
    } catch (e) {
      return null;
    }
  }
  
  /// AI System: Find nearby points within radius
  /// Used by AI services for proximity-based features
  List<Point> findNearbyPoints(Point center, List<Point> points, double radiusMeters) {
    return points.where((point) => 
      CoordinateHelpers.isWithinRadius(center, point, radiusMeters)
    ).toList();
  }
  
  /// AI System: Get optimal camera position for multiple points
  /// Used by AI services that need to show multiple locations
  Map<String?, Object?> getOptimalCameraPosition(List<Point> points) {
    if (points.isEmpty) {
      return {
        'center': {'lng': 0.0, 'lat': 0.0},
        'zoom': 10.0
      };
    }
    
    if (points.length == 1) {
      return CoordinateHelpers.pointToCameraCenter(points.first);
    }
    
    return CoordinateHelpers.pointsToCameraBounds(points);
  }

  // ===== MAP RENDERING INTERFACE (Map-based) =====
  
  /// Map System: Convert Point to CameraOptions.center
  /// Used by map screens that need to center camera
  Map<String?, Object?> pointToCameraCenter(Point point) {
    return CoordinateHelpers.pointToCameraCenter(point);
  }
  
  /// Map System: Convert Point to PointAnnotationOptions.geometry
  /// Used by map screens that need to place markers
  Map<String?, Object?> pointToAnnotationGeometry(Point point) {
    return CoordinateHelpers.pointToAnnotationGeometry(point);
  }
  
  /// Map System: Convert Point to CircleAnnotationOptions.center
  /// Used by map screens that need to draw circles
  Map<String?, Object?> pointToCircleCenter(Point point) {
    return CoordinateHelpers.pointToCircleCenter(point);
  }
  
  /// Map System: Convert multiple Points to PolylineAnnotationOptions.geometry
  /// Used by map screens that need to draw routes
  Map<String?, Object?> pointsToPolylineGeometry(List<Point> points) {
    return CoordinateHelpers.pointsToPolylineGeometry(points);
  }
  
  /// Map System: Convert Point to CameraBounds
  /// Used by map screens that need to fit multiple points in view
  Map<String?, Object?> pointsToCameraBounds(List<Point> points) {
    return CoordinateHelpers.pointsToCameraBounds(points);
  }

  // ===== FIREBASE/FIRESTORE INTERFACE =====
  
  /// Database: Convert Point to Firestore GeoPoint
  /// Used when saving location data to database
  GeoPoint pointToGeoPoint(Point point) {
    return CoordinateHelpers.pointToGeoPoint(point);
  }
  
  /// Database: Convert Firestore GeoPoint to Point
  /// Used when reading location data from database
  Point geoPointToPoint(GeoPoint geoPoint) {
    return CoordinateHelpers.geoPointToPoint(geoPoint);
  }
  
  /// Database: Convert Point to Firestore document data
  /// Used when saving location data with metadata
  Map<String, dynamic> pointToFirestoreData(Point point, {String? label}) {
    return CoordinateHelpers.pointToFirestoreData(point, label: label);
  }

  // ===== GEOLOCATOR INTERFACE =====
  
  /// Device: Convert Point to Geolocator Position
  /// Used when working with device location APIs
  geolocator.Position pointToGeolocatorPosition(Point point) {
    return CoordinateHelpers.pointToGeolocatorPosition(point);
  }
  
  /// Device: Convert Geolocator Position to Point
  /// Used when receiving device location updates
  Point geolocatorPositionToPoint(geolocator.Position position) {
    return CoordinateHelpers.geolocatorPositionToPoint(position);
  }

  // ===== UTILITY FUNCTIONS =====
  
  /// Utility: Calculate distance between two points
  double calculateDistance(Point point1, Point point2) {
    return CoordinateHelpers.calculateDistance(point1, point2);
  }
  
  /// Utility: Check if point is within radius
  bool isWithinRadius(Point center, Point point, double radiusMeters) {
    return CoordinateHelpers.isWithinRadius(center, point, radiusMeters);
  }
  
  /// Utility: Get midpoint between two points
  Point getMidpoint(Point point1, Point point2) {
    return CoordinateHelpers.getMidpoint(point1, point2);
  }
  
  /// Utility: Validate coordinate bounds
  bool isValidCoordinateBounds(double lat, double lng) {
    return CoordinateHelpers.isValidCoordinateBounds(lat, lng);
  }
  
  /// Utility: Create Point with validation
  Point? createValidPoint(double latitude, double longitude) {
    return CoordinateHelpers.createValidPoint(latitude, longitude);
  }
  
  /// Utility: Convert multiple Points to coordinate arrays
  List<List<double>> pointsToCoordinateArrays(List<Point> points) {
    return CoordinateHelpers.pointsToCoordinateArrays(points);
  }
  
  /// Utility: Convert coordinate arrays to Points
  List<Point> coordinateArraysToPoints(List<List<double>> coordinates) {
    return CoordinateHelpers.coordinateArraysToPoints(coordinates);
  }

  // ===== MAPBOX API INTERFACE =====
  
  /// Mapbox API: Convert Point to coordinate string
  String pointToMapboxCoordinateString(Point point) {
    return CoordinateHelpers.pointToMapboxCoordinateString(point);
  }
  
  /// Mapbox API: Convert multiple Points to waypoints string
  String pointsToMapboxWaypoints(List<Point> points) {
    return CoordinateHelpers.pointsToMapboxWaypoints(points);
  }
  
  /// Mapbox API: Parse API response to Points
  List<Point> parseMapboxCoordinates(Map<String, dynamic> response) {
    return CoordinateHelpers.parseMapboxCoordinates(response);
  }

  // ===== AI SYSTEM ADVANCED FEATURES =====
  
  /// AI System: Get location context for AI processing
  /// Used by AI services that need location context
  Map<String, dynamic> getLocationContext(Point point) {
    return {
      'coordinates': CoordinateHelpers.pointToMap(point),
      'timestamp': DateTime.now().toIso8601String(),
      'accuracy': 'high',
      'source': 'ai_system',
    };
  }
  
  /// AI System: Process location data for AI learning
  /// Used by AI services that learn from location patterns
  Map<String, dynamic> processLocationForAI(Point point, String context) {
    return {
      'location': CoordinateHelpers.pointToMap(point),
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
      'processed': true,
    };
  }
  
  /// AI System: Get location statistics for AI analysis
  /// Used by AI services that analyze location patterns
  Map<String, dynamic> getLocationStatistics(List<Point> points) {
    if (points.isEmpty) {
      return {
        'total_points': 0,
        'average_distance': 0.0,
        'bounding_box': null,
      };
    }
    
    double totalDistance = 0.0;
    double minLat = points.first.coordinates.lat.toDouble();
    double maxLat = points.first.coordinates.lat.toDouble();
    double minLng = points.first.coordinates.lng.toDouble();
    double maxLng = points.first.coordinates.lng.toDouble();
    
    for (int i = 1; i < points.length; i++) {
      totalDistance += CoordinateHelpers.calculateDistance(points[i-1], points[i]);
      
      final lat = points[i].coordinates.lat.toDouble();
      final lng = points[i].coordinates.lng.toDouble();
      
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }
    
    return {
      'total_points': points.length,
      'average_distance': totalDistance / (points.length - 1),
      'bounding_box': {
        'northeast': {'lng': maxLng, 'lat': maxLat},
        'southwest': {'lng': minLng, 'lat': minLat}
      },
      'center': CoordinateHelpers.pointToMap(
        CoordinateHelpers.getMidpoint(points.first, points.last)
      ),
    };
  }
}
