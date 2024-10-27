import 'dart:async';
import 'dart:convert';
import 'package:car_pool/handlers/location_task_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class LocationService {
  final String _googleApiKey = 'YOUR_GOOGLE_API_KEY';
  static StreamSubscription<Position>? _positionSubscription;

  Future<Position> getCurrentLocation() async {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10,
    );

    try {
      return await Geolocator.getCurrentPosition(
          locationSettings: locationSettings);
    } catch (e) {
      throw Exception('Error getting current location: $e');
    }
  }

  // Method to get the destination's coordinates based on the place ID
  Future<LatLng?> getDestinationDetails(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final location = data['result']['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    } else {
      throw Exception('Failed to fetch destination details');
    }
  }

  // Method to get the route and estimated time of arrival between two points
  Future<Map<String, dynamic>> getRouteAndEta(LatLng start, LatLng end) async {
    final String url =
        'https://routes.googleapis.com/directions/v2:computeRoutes?key=$_googleApiKey';

    final requestBody = jsonEncode({
      "origin": {
        "location": {
          "latLng": {
            "latitude": start.latitude,
            'longitude': start.longitude,
          }
        }
      },
      "destination": {
        "location": {
          "latLng": {
            "latitude": end.latitude,
            "longitude": end.longitude,
          }
        }
      },
      "travelMode": "DRIVE",
      "routingPreference": "TRAFFIC_AWARE",
      "computeAlternativeRoutes": false,
      "routeModifiers": {
        "avoidTolls": false,
        "avoidHighways": false,
        "avoidFerries": true,
      },
      "languageCode": "en-US",
      "units": "METRIC",
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-FieldMask':
              'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'].isNotEmpty) {
          var route = data['routes'][0];
          return {
            'distanceMeters': route['distanceMeters'],
            'duration': route['duration'],
            'polylinePoints': route['polyline']['encodedPolyline'],
          };
        } else {
          throw Exception('No route found');
        }
      } else {
        throw Exception('Failed to fetch directions: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error occurred during API request: $e');
    }
  }

  // Method to decode polyline for drawing route
  List<LatLng> decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  // Real-time location tracking using Geolocator
  static Future<void> startLocationTracking({
    required Function(Position) onPositionUpdate,
  }) async {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      onPositionUpdate(position);
    });
  }

  // Stop real-time location tracking
  static void stopLocationTracking() {
    _positionSubscription?.cancel();
  }

  // Background location tracking using geolocator
  static Future<void> startBackgroundTracking({
    required Function(Position) onPositionUpdate,
  }) async {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      onPositionUpdate(position);
    });
  }

  static Future<void> startForegroundService() async {
    await FlutterForegroundTask.startService(
      notificationTitle: 'Background Location Service',
      notificationText: 'Tracking your location',
      callback: locationCallback,
    );
  }

  static Future<void> stopForegroundService() async {
    await FlutterForegroundTask.stopService();
  }

  static void locationCallback() {
    FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
  }
}
