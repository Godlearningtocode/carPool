import 'package:car_pool/my_app_state.dart';
import 'package:car_pool/trip_map_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class DriverTripHistoryPage extends StatelessWidget {
  Future<List<Map<String, dynamic>>> fetchTripHistory(String idToken) async {
    const url =
        'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/DriverTrip';
    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      return (jsonResponse['documents'] as List).map((doc) {
        List tripData = (doc['fields']['tripData']['arrayValue']['values']
                as List)
            .map((point) {
              var latitude =
                  point['mapValue']['fields']['latitude']['doubleValue'];
              var longitude =
                  point['mapValue']['fields']['longitude']['doubleValue'];
              var timeStamp =
                  point['mapValue']['fields']['timeStamp']['timestampValue'];

              // Check if any of these values are null and handle appropriately
              if (latitude == null || longitude == null || timeStamp == null) {
                return null; // Skip this entry if there's missing data
              }

              return {
                'latitude': latitude,
                'longitude': longitude,
                'timeStamp': timeStamp,
              };
            })
            .where((point) => point != null) // Filter out any null entries
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

        // Extract the start and end time safely
        var startTime =
            doc['fields']['startTime']['timestampValue'] ?? "Unknown";
        var endTime = doc['fields']['endTime']['timestampValue'] ?? "Unknown";

        String formattedStartTime = startTime != "Unknown"
            ? DateFormat.yMMMd().add_jm().format(DateTime.parse(startTime))
            : startTime;
        String formattedEndTime = endTime != "Unknown"
            ? DateFormat.yMMMd().add_jm().format(DateTime.parse(endTime))
            : endTime;

        return {
          'driver': doc['fields']['driver']['stringValue'] ?? "Unknown",
          'startTime': formattedStartTime,
          'endTime': formattedEndTime,
          'tripData': tripData,
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch trip history ${response.body}');
    }
  }

  String formatDateTime(String timestamp) {
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      return DateFormat('dd MMM yyy, hh:mm a').format(dateTime);
    } catch (e) {
      print('invalid timestamp: $timestamp');
      return "invalid date";
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<MyAppState>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Trip history'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchTripHistory(appState.idToken!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return ListView(
              children: snapshot.data!.map((trip) {
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TripMapPage(tripData: trip['tripData']),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: ListTile(
                      leading: Icon(
                        Icons.map,
                        color: Colors.blue,
                      ),
                      title: Text(
                        'Driver: ${trip['driver']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle:
                          Text('${trip['startTime']} - ${trip['endTime']}'),
                      trailing: Icon(Icons.arrow_forward),
                    ),
                  ),
                );
              }).toList(),
            );
          }
        },
      ),
    );
  }
}
