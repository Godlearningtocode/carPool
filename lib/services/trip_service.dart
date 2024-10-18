import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:car_pool/utils/date_time_util.dart'; // Date-time utility

class TripService {
  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/DriverTrip';

  // Fetches trip history for all drivers
  static Future<Map<String, List<Map<String, dynamic>>>> fetchTripHistory(
      String idToken) async {
    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final response = await http.get(Uri.parse(_baseUrl), headers: headers);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      Map<String, List<Map<String, dynamic>>> groupedTrips = {};

      for (var doc in jsonResponse['documents']) {
        List tripData = (doc['fields']['tripData']['arrayValue']['values']
                as List)
            .map((point) {
              var latitude =
                  point['mapValue']['fields']['latitude']['doubleValue'];
              var longitude =
                  point['mapValue']['fields']['longitude']['doubleValue'];
              var timeStamp =
                  point['mapValue']['fields']['timeStamp']['timestampValue'];

              if (latitude == null || longitude == null || timeStamp == null) {
                return null;
              }

              return {
                'latitude': latitude,
                'longitude': longitude,
                'timeStamp': timeStamp,
              };
            })
            .where((point) => point != null)
            .toList();

        tripData.sort((a, b) {
          DateTime? dateA, dateB;
          try {
            dateA = DateTime.parse(a['timeStamp']);
            dateB = DateTime.parse(b['timeStamp']);
          } catch (e) {
            print(
                "Invalid timestamp format found: ${a['timeStamp']} or ${b['timeStamp']}");
          }
          return dateA?.compareTo(dateB ?? DateTime.now()) ?? 0;
        });

        var driverName =
            doc['fields']['driver']['stringValue'] ?? 'Unknown Driver';
        var startTime =
            doc['fields']['startTime']['timestampValue'] ?? "Unknown";
        var endTime = doc['fields']['endTime']['timestampValue'] ?? "Unknown";

        if (!groupedTrips.containsKey(driverName)) {
          groupedTrips[driverName] = [];
        }

        groupedTrips[driverName]?.add({
          'startTime': startTime,
          'endTime': endTime,
          'tripData': tripData,
        });
      }

      return groupedTrips;
    } else {
      throw Exception('Failed to fetch trip history ${response.body}');
    }
  }

  // Method to save trip data for a driver
  static Future<void> saveTripData({
    required String idToken,
    required String driverName,
    required String tripId,
    required List<Map<String, dynamic>> tripData,
  }) async {
    final url =
        '$_baseUrl/$driverName/trips?documentId=$tripId';

    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'fields': {
        'driver': {'stringValue': driverName},
        'tripData': {
          'arrayValue': {
            'values': tripData.map((tripPoint) {
              return {
                'mapValue': {
                  'fields': {
                    'latitude': {'doubleValue': tripPoint['latitude']},
                    'longitude': {'doubleValue': tripPoint['longitude']},
                    'timeStamp': {
                      'timestampValue': DateTimeUtil.convertToFirestoreTimestamp(
                          tripPoint['timeStamp']),
                    },
                  }
                }
              };
            }).toList(),
          }
        },
        'startTime': {
          'timestampValue': DateTimeUtil.convertToFirestoreTimestamp(
              tripData.first['timeStamp']),
        },
        'endTime': {
          'timestampValue': DateTimeUtil.convertToFirestoreTimestamp(
              DateTime.now().toIso8601String()),
        }
      }
    });

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode != 200) {
        throw Exception('Error saving trip data: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error saving trip data: $e');
    }
  }

  // Method to update the trip location during the active trip
  static Future<void> updateTripLocation({
    required String idToken,
    required String driverName,
    required String tripId,
    required Map<String, dynamic> lastTripPoint,
  }) async {
    final url =
        '$_baseUrl/$driverName/trips/$tripId';

    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'fields': {
        'tripData': {
          'arrayValue': {
            'values': [
              {
                'mapValue': {
                  'fields': {
                    'latitude': {'doubleValue': lastTripPoint['latitude']},
                    'longitude': {'doubleValue': lastTripPoint['longitude']},
                    'timeStamp': {
                      'timestampValue': DateTimeUtil.convertToFirestoreTimestamp(
                          lastTripPoint['timeStamp'])
                    },
                  }
                }
              }
            ]
          }
        }
      }
    });

    try {
      final response =
          await http.patch(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode != 200) {
        throw Exception('Error updating trip location: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating trip location: $e');
    }
  }
}
