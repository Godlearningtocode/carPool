import 'dart:async';
import 'package:car_pool/mock_trip_data.dart';
import 'package:car_pool/providers/my_app_state.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:car_pool/services/location_service.dart';
import 'package:car_pool/services/trip_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class DriverHomePage extends StatefulWidget {
  @override
  _DriverHomepageState createState() => _DriverHomepageState();
}

class _DriverHomepageState extends State<DriverHomePage> {
  bool _isTripActive = false;
  List<Map<String, dynamic>> _tripData = [];
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
        // _updateTripLocation(driverName);
      }
    });
  }

  String generateUniqueTripId(String passengerName) {
    var uuid = Uuid();
    String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '$timestamp-${passengerName.isNotEmpty ? passengerName : uuid.v4()}';
  }

  Future<void> _endTrip(String? idToken, String driverName) async {
    setState(() {
      _isTripActive = false;
    });

    print(driverName);

    String tripId = generateUniqueTripId('AyusshAgarwwal');

    if (_tripId != null) {
      await TripService.saveTripData(
        idToken: idToken!,
        driverName: driverName,
        tripId: tripId,
        tripData: getMockTripData(),
      );
    }

    _tripData.clear();
    LocationService.stopLocationTracking();
  }

  // Future<void> _updateTripLocation(String driverName) async {
  //   var appState = Provider.of<MyAppState>(context, listen: false);
  //   if (_tripData.isEmpty) return;

  //   Map<String, dynamic> lastTripPoint = _tripData.last;

  //   if (_tripId != null) {
  //     await TripService.updateTripLocation(
  //       idToken: appState.idToken!,
  //       driverName: driverName,
  //       tripId: _tripId!,
  //       lastTripPoint: lastTripPoint,
  //     );
  //   }
  // }

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
                    String driverName = appState.driverName ?? 'unknown driver';
                    print('driverhomepage 118 $driverName');
                    await _startTrip(driverName);
                  },
                  child: Text('Start Trip')),
            if (_isTripActive)
              ElevatedButton(
                onPressed: () async {
                  String driverName = appState.driverName ?? 'unknown driver';
                  await _endTrip(appState.idToken, driverName);
                },
                child: Text('End Trip'),
              ),
            SizedBox(height: 20),
            Text(_isTripActive ? 'Trip is in progress' : 'No active trip'),
          ],
        ),
      ),
    );
  }
}
