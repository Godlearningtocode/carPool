import 'package:car_pool/my_app_state.dart';
import 'package:car_pool/trip_map_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class DriverTripHistoryPage extends StatelessWidget {
  Future<Map<String, List<Map<String, dynamic>>>> fetchTripHistory(
      String idToken) async {
    const url =
        'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/DriverTrip';
    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final response = await http.get(Uri.parse(url), headers: headers);

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
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
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
            final groupedTrips = snapshot.data!;
            return ListView(
                children: groupedTrips.entries.map(
              (entry) {
                final driverName = entry.key;
                final trips = entry.value;

                return ExpansionTile(
                  title: Text(
                    driverName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  children: trips.map((trip) {
                    return ListTile(
                      title: Text(
                        'Trip: ${formatDateTime(trip['startTime'])} - ${formatDateTime(trip['endTime'])}',
                      ),
                      trailing: Icon(Icons.map),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TripMapPage(tripData: trip['tripData']),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ).toList());
          }
        },
      ),
    );
  }
}
