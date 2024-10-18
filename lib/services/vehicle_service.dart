// services/vehicle_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class VehicleService {
  final String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents';

  Future<void> addOrUpdateVehicleStatus(
      String idToken, String registrationNumber, String driverName) async {
    final url =
        '$_baseUrl/vehicles/$registrationNumber?documentId=$registrationNumber';

    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'fields': {
        'registrationNumber': {'stringValue': registrationNumber},
        'driverName': {'stringValue': driverName},
      }
    });

    final response =
        await http.patch(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception('Failed to add or update vehicle: ${response.body}');
    }
  }
}
