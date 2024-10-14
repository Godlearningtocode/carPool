import 'dart:convert';
import 'package:http/http.dart' as http;

class VehicleManager {
  Future<void> addOrUpdateVehicleStatus(
      String idToken, String registrationNumber, String driverName) async {
    final url =
        'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/vehicles?documentId=$registrationNumber';

    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'fields': {
        'registrationNumber': {'stringValue': registrationNumber},
        'status': {'stringValue': 'idle'},
        'driverName': {'stringValue': driverName},
        'passengers': {
          'arrayValue': {'values': []}
        },
        'maxPassengers': {'integerValue': '4'},
      }
    });

    final response =
        await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode == 200) {
      print('Vehicle added or updated successfully via REST API');
    } else {
      print('Error adding or updating vehicle: ${response.body}');
    }
  }
}
