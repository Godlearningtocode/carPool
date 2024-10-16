import 'package:car_pool/my_app_state.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class DriverTripHistoryPage extends StatelessWidget {
  Future<List<Map<String, dynamic>>> fetchTrupHistory(String idToken) async {
    final url =
        'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/DriverTrips';
    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return (jsonResponse['doxuments'] as List).map((doc) {
        List tripData =
            (doc['fields']['tripData']['arrayValue']['values'] as List)
                .map((point) => {
                      'latitude': point['mapValue']['fields']['latitude']
                          ['doubleValue'],
                      'longitude': point['mapValue']['fields']['longitude']
                          ['doubleValue'],
                      'timeStamp': point['mapValue']['fields']['timeStamp']
                          ['stringValue'],
                    })
                .toList();

        tripData.sort((a, b) => DateTime.parse(a['timeStamp'])
            .compareTo(DateTime.parse(b['timeStamp'])));

        return {
          'driver': doc['fields']['driver']['stringValue'],
          'startTime': doc['fields']['startTime']['stringValue'],
          'endTime': doc['fields']['endTime']['stringValue'],
          'tripData': doc['fields']['tripData']['arrayValue']['values'],
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch trip history');
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
        future: fetchTrupHistory(appState.idToken!),
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
                return ListTile(
                  title: Text('Driver: ${trip['driver']}'),
                  subtitle:
                      Text('Trip: ${trip['startTime']} - ${trip['endTime']}'),
                );
              }).toList(),
            );
          }
        },
      ),
    );
  }
}
