// roads_service.dart
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RoadsService {
  static const String _apiKey = 'AIzaSyDUXyVASgZtmw4g1BYQyDNj0J0s7_3Dyjo';

  // Method to snap the path to roads
  Future<List<LatLng>> snapToRoads(List<LatLng> pathCoordinates) async {
    String path = pathCoordinates
        .map((point) => '${point.latitude},${point.longitude}')
        .join('|');

    String url =
        "https://roads.googleapis.com/v1/snapToRoads?path=$path&interpolate=true&key=$_apiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['snappedPoints'] != null) {
          return (jsonResponse['snappedPoints'] as List).map((point) {
            var location = point['location'];
            return LatLng(location['latitude'], location['longitude']);
          }).toList();
        }
      } else {
        print('Failed to snap roads: ${response.body}');
      }
    } catch (e) {
      print('Error calling Roads API: $e');
    }
    return [];
  }
}
