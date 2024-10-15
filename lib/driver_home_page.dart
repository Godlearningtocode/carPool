import 'dart:async';
import 'dart:convert';
import 'package:car_pool/login_page.dart';
import 'package:car_pool/my_app_state.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class DriverHomePage extends StatefulWidget {
  @override
  _DriverHomepageState createState() => _DriverHomepageState();
}

class _DriverHomepageState extends State<DriverHomePage> {
  bool _isTripActive = false;
  List<Map<String, dynamic>> _tripData = [];
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _startTrip() async {
    setState(() {
      _isTripActive = true;
    });

    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );

    StreamSubscription<Position> positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      if (_isTripActive) {
        _tripData.add({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timeStamp': DateTime.now().toIso8601String(),
        });

        setState(() {});
      }
    });

    _positionStreamSubscription = positionStreamSubscription;
  }

  Future<void> _endTrip(String? idToken) async {
    setState(() {
      _isTripActive = false;
    });

    _positionStreamSubscription?.cancel();

    final url =
        'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/DriverTrip';

    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'fields': {
        'driver': {'stringValue': 'Driver name'},
        'tripData': {
          'arrayValue': {
            'values': _tripData.map((tripPoint) {
              return {
                'mapValue': {
                  'fields': {
                    'latitude': {'doubleValue': tripPoint['latitude']},
                    'longitude': {'doubleValue': tripPoint['longitude']},
                    'timeStamp': {'stringValue': tripPoint['timeStamp']}
                  }
                }
              };
            }).toList()
          }
        },
        'startTime': {
          'timeStampValue': _tripData.first['timeStamp'],
        },
        'endTime': DateTime.now().toIso8601String(),
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
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => LoginPage()));
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
                    await _startTrip();
                  },
                  child: Text('Start Trip')),
            if (_isTripActive)
              ElevatedButton(
                onPressed: () async {
                  await _endTrip(appState.idToken);
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
