import 'dart:convert';
import 'package:http/http.dart' as http;

class VehicleManager {
  Future<void> addOrUpdateVehicleStatus(String idToken, String registrationNumber, String driver) async {
    final url = 'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/vehicles/$registrationNumber';

    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'fields': {
        'registrationNumber': {'stringValue': registrationNumber},
        'driver': {'stringValue': driver},
        'status': {'stringValue': 'active'},  // Example field, can be expanded
      }
    });

    final response = await http.patch(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception('Failed to add or update vehicle status');
    }
  }

  Future<void> updateVehicleStatus(String idToken, String registrationNumber, String newStatus) async {
    final url = 'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/vehicles/$registrationNumber';

    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'fields': {
        'status': {'stringValue': newStatus}
      }
    });

    final response = await http.patch(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception('Failed to update vehicle status');
    }
  }

  // Other vehicle-related logic can go here
}
