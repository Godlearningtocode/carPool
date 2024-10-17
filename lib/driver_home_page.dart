import 'dart:async';
import 'dart:convert';
import 'package:car_pool/my_app_state.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'package:provider/provider.dart';

class DriverHomePage extends StatefulWidget {
  @override
  _DriverHomepageState createState() => _DriverHomepageState();
}

class _DriverHomepageState extends State<DriverHomePage> {
  bool _isTripActive = false;
  List<Map<String, dynamic>> _tripData = [];
  StreamSubscription<Position>? _positionStreamSubscription;
  String? _tripId;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _startTrip(String driverName) async {
    setState(() {
      _isTripActive = true;
    });

    _tripId = DateTime.now().millisecondsSinceEpoch.toString();

    await LocationService.startLocationTracking(
        onPositionUpdate: (Position position) {
      if (_isTripActive) {
        _tripData.add({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timeStamp': DateTime.now().toIso8601String(),
        });

        // Update Firestore with the new position
        _updateTripLocation(driverName);
      }
    });

    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      if (_isTripActive) {
        _tripData.add({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timeStamp': DateTime.now().toIso8601String(),
        });

        setState(() {}); // Update UI
      }
    });
  }

  Future<void> _endTrip(String? idToken, String driverName) async {
    setState(() {
      _isTripActive = false;
    });

    _positionStreamSubscription?.cancel();

    final tripId = DateTime.now()
        .millisecondsSinceEpoch
        .toString(); // Use timestamp as trip ID
    final url =
        'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/DriverTrip/${driverName}/trips?documentId=${tripId}';

    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'fields': {
        'driver': {'stringValue': driverName},
        'tripData': {
          'arrayValue': {
            'values': _tripData.map((tripPoint) {
              return {
                'mapValue': {
                  'fields': {
                    'latitude': {'doubleValue': tripPoint['latitude']},
                    'longitude': {'doubleValue': tripPoint['longitude']},
                    'timeStamp': {
                      'timestampValue':
                          _convertToFirestoreTimestamp((tripPoint['timeStamp']))
                    },
                  }
                }
              };
            }).toList()
          }
        },
        'startTime': {
          'timestampValue':
              _convertToFirestoreTimestamp(_tripData.first['timeStamp']),
        },
        'endTime': {
          'timestampValue':
              _convertToFirestoreTimestamp(DateTime.now().toIso8601String()),
        }
      }
    });

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        print('trip data saved succesfully');
        _tripData.clear();
      } else {
        print('Error saving trip data: ${response.body}');
      }
    } catch (e) {
      print(('error during trip saving $e'));
    }

    LocationService.stopLocationTracking();
  }

  Future<void> _updateTripLocation(String driverName) async {
    final idToken = Provider.of<MyAppState>(context, listen: false).idToken;
    if (_tripData.isEmpty) return; // Ensure there are data points

    // Get the most recent trip point (i.e., the last one in the list)
    Map<String, dynamic> lastTripPoint = _tripData.last;

    final url =
        'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/DriverTrip/$driverName/trips/$_tripId';

    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'fields': {
        'driver': {
          'stringValue': 'Driver name'
        }, // You can modify this to use the actual driver's name.
        'tripData': {
          'arrayValue': {
            'values': [
              {
                'mapValue': {
                  'fields': {
                    'latitude': {'doubleValue': lastTripPoint['latitude']},
                    'longitude': {'doubleValue': lastTripPoint['longitude']},
                    'timeStamp': {
                      'timestampValue': _convertToFirestoreTimestamp(
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

      if (response.statusCode == 200) {
        print('Updated last trip data point successfully.');
      } else {
        print('Error updating trip location: ${response.body}');
      }
    } catch (e) {
      print('Error during trip location update: $e');
    }
  }

  String _convertToFirestoreTimestamp(String dateTime) {
    DateTime parsedDate = DateTime.parse(dateTime).toUtc();
    return parsedDate.toIso8601String();
  }

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<MyAppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Home'),
        actions: [
          IconButton(
            onPressed: () async {
              appState.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: Icon(Icons.logout),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isTripActive)
              ElevatedButton(
                  onPressed: () async {
                    String driverName = appState.driverName ?? 'unknwon driver';
                    print('219 driver home page $driverName ${appState.driverName}');
                    await _startTrip(driverName);
                  },
                  child: Text('Start Trip')),
            if (_isTripActive)
              ElevatedButton(
                onPressed: () async {
                  String driverName = appState.driverName ?? 'unknown';
                  await _endTrip(appState.idToken, driverName);
                },
                child: Text('end trip'),
              ),
            SizedBox(
              height: 20,
            ),
            Text(_isTripActive ? 'Trip is in progress' : 'No active trip'),
          ],
        ),
      ),
    );
  }
}
