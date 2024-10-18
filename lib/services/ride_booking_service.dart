import 'dart:convert';
import 'package:http/http.dart' as http;

class RideBookingService {
  final String _placesApiKey = 'YOUR_API_KEY';
  final String vehiclesUrl = 'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/vehicles';

  Future<List<Map<String, dynamic>>> fetchVehicles(String idToken) async {
    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(vehiclesUrl), headers: headers);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['documents'] != null) {
          return (jsonResponse['documents'] as List).map((doc) {
            final registrationNumber = doc['fields']?['registrationNumber']?['stringValue'] ?? 'Unknown';
            final passengersArray = doc['fields']?['passengers']?['arrayValue']?['values'] ?? [];
            final maxPassengers = int.tryParse(doc['fields']?['maxPassengers']?['integerValue'] ?? '4') ?? 4;

            final availableSeats = maxPassengers - passengersArray.length;

            return {
              'registrationNumber': registrationNumber,
              'availableSeats': availableSeats,
              'status': doc['fields']?['status']?['stringValue'] ?? 'unknown',
              'driverName': doc['fields']?['driverName']?['stringValue'] ?? 'unknown',
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching vehicles: $e');
    }
  }

  Future<void> updateVehicleAfterBooking(String idToken, String registrationNumber, String passengerName) async {
    final vehicleUrl = '$vehiclesUrl/$registrationNumber?updateMask.fieldPaths=passengers';
    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.patch(
        Uri.parse(vehicleUrl),
        headers: headers,
        body: jsonEncode({
          'fields': {
            'passengers': {
              'arrayValue': {
                'values': [{'stringValue': passengerName}]
              }
            }
          }
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error updating vehicle: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating vehicle: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAutoCompleteSuggestions(String input) async {
    if (input.isEmpty) return [];

    final String requestUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_placesApiKey&types=geocode';
    try {
      final response = await http.get(Uri.parse(requestUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['predictions'] as List).map((prediction) {
          return {
            'description': prediction['description'],
            'placeId': prediction['place_id'],
          };
        }).toList();
      }
    } catch (e) {
      throw Exception('Error fetching autocomplete suggestions: $e');
    }
    return [];
  }
}
