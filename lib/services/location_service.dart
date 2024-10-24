import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:background_locator_2/background_locator.dart';
import 'package:background_locator_2/location_dto.dart';
import 'package:background_locator_2/settings/locator_settings.dart' as BackgroundLocatorSettings;
import 'package:background_locator_2/settings/android_settings.dart' as BackgroundLocatorAndroidSettings;
import 'package:background_locator_2/settings/ios_settings.dart' as BackgroundLocatorIosSettings;

class LocationService {
  final String _googleApiKey = 'YOUR_GOOGLE_API_KEY';
  static StreamSubscription<Position>? _positionSubscription;

  // Method to get the current location of the user
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

  Future<void> initalizeBackgroundLocator() async {
    await BackgroundLocator.initialize();
    print('Background Locator initalized');
  }

  static void startBackgroundTracking() {
    BackgroundLocator.registerLocationUpdate(
      locationCallback,
       androidSettings: BackgroundLocatorAndroidSettings.AndroidSettings(
        accuracy: BackgroundLocatorSettings.LocationAccuracy.NAVIGATION,
        interval: 5, // Location updates every 5 seconds
        distanceFilter: 0,
        androidNotificationSettings: BackgroundLocatorAndroidSettings.AndroidNotificationSettings(
          notificationTitle: "Background Location Service",
          notificationMsg: "Location tracking is active",
          notificationIcon: "@mipmap/ic_launcher", // Change this to your notification icon
        ),
      ),
      iosSettings: BackgroundLocatorIosSettings.IOSSettings(
        accuracy: BackgroundLocatorSettings.LocationAccuracy.NAVIGATION,
        distanceFilter: 0,
      ),
    );
  }

  static void stopBackgroundTracking() {
    BackgroundLocator.unRegisterLocationUpdate();
    print("background tracking stopped");
  }
}

void locationCallback(LocationDto locationDto) {
  print(
      'background location update: ${locationDto.latitude}, ${locationDto.longitude}');
}
