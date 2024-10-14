// ignore_for_file: unused_field

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LocationPage extends StatefulWidget {
  final String destination;
  final String placeId;

  LocationPage({required this.destination, required this.placeId});

  @override
  LocationPageState createState() => LocationPageState();
}

class LocationPageState extends State<LocationPage> {
  Position? _currentPosition;
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  Marker? _destinationMarker;
  Polyline? _routePolyline;
  String? _etaText;
  final String _googleApiKey = 'AIzaSyDUXyVASgZtmw4g1BYQyDNj0J0s7_3Dyjo';

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location services are disbaled')));
      });

      bool locationSettingsOpened = await Geolocator.openLocationSettings();

      if (!locationSettingsOpened) {
        return;
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Locaition permissions are denied')));
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Location permissions are permanently denied, please enable them from the settings')));
      });
      return;
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      );

      Position position = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings);
      setState(() {
        _currentPosition = position;
        _currentLatLng = LatLng(position.latitude, position.longitude);
      });
      _fetchDestinationDetails(widget.placeId);
    } catch (e) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      });
    }
  }

  Future<void> _fetchDestinationDetails(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final location = data['result']['geometry']['location'];
      final LatLng destinationPosition =
          LatLng(location['lat'], location['lng']);

      setState(() {
        _destinationMarker = Marker(
            markerId: MarkerId('destination'),
            position: destinationPosition,
            infoWindow:
                InfoWindow(title: 'Destination', snippet: widget.destination));
      });
      if (_currentLatLng != null) {
        _drawRouteAndEta(_currentLatLng!, destinationPosition);
      }
    } else {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch destination details')));
      });
    }
  }

  Future<void> _drawRouteAndEta(LatLng start, LatLng end) async {
    final String url =
        'https://routes.googleapis.com/directions/v2:computeRoutes?key=$_googleApiKey';

    final requestBody = jsonEncode({
      "origin": {
        "location": {
          "latLng": {
            "latitude": start.latitude,
            'longitude': start.longitude,
          }
        }
      },
      "destination": {
        "location": {
          "latLng": {
            "latitude": end.latitude,
            "longitude": end.longitude,
          }
        }
      },
      "travelMode": "DRIVE",
      "routingPreference": "TRAFFIC_AWARE",
      "computeAlternativeRoutes": false,
      "routeModifiers": {
        "avoidTolls": false,
        "avoidHighways": false,
        "avoidFerries": true,
      },
      "languageCode": "en-US",
      "units": "METRIC",
    });

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-FieldMask':
                  'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline',
            },
            body: requestBody,
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'].isNotEmpty) {
          var route = data['routes'][0];
          var distanceMeters = route['distanceMeters'];
          var duration = route['duration'];
          var polylinePoints = route['polyline']['encodedPolyline'];

          List<LatLng> decodedPolyline = _decodePolyline(polylinePoints);

          double distanceKm = distanceMeters / 1000;

          String durationString = duration.toString();
          if (durationString.endsWith('s')) {
            durationString = durationString.replaceAll('s', '');
          }

          int durationSeconds = int.tryParse(durationString) ?? 0;
          int durationMinutes = (durationSeconds / 60).round();

          setState(() {
            _etaText =
                'ETA: $durationMinutes min, distance: ${distanceKm.toStringAsFixed(1)} km';
            _routePolyline = Polyline(
                polylineId: PolylineId('route'),
                color: Colors.blue,
                width: 5,
                points: decodedPolyline);
          });

          _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
              LatLngBounds(
                  southwest: LatLng(
                      start.latitude < end.latitude
                          ? start.latitude
                          : end.latitude,
                      start.longitude < end.longitude
                          ? start.longitude
                          : end.longitude),
                  northeast: LatLng(
                      start.latitude > end.latitude
                          ? start.latitude
                          : end.latitude,
                      start.longitude > end.longitude
                          ? start.longitude
                          : end.longitude)),
              50.0));
        } else {
          setState(() {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('No route found')));
          });
        }
      } else {
        setState(() {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed to directions')));
        });
      }
    } catch (e) {
      print('Error occured during API request: $e');
    }
  }

  List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result & 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Route to destination'),
        ),
        body: Stack(
          children: [
            _currentPosition == null && _destinationMarker == null
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: _currentLatLng!, zoom: 14.0),
                    myLocationEnabled: true,
                    markers:
                        _destinationMarker != null ? {_destinationMarker!} : {},
                    polylines: _routePolyline != null ? {_routePolyline!} : {},
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                  ),
            if (_etaText != null)
              Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                      padding: EdgeInsets.all(8),
                      color: Colors.white,
                      child: Text(
                        _etaText!,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      )))
          ],
        ));
  }
}
