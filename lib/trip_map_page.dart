import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class TripMapPage extends StatefulWidget {
  final List tripData;

  TripMapPage({required this.tripData});

  @override
  _TripMapPageState createState() => _TripMapPageState();
}

class _TripMapPageState extends State<TripMapPage> {
  GoogleMapController? _mapController;
  List<LatLng> _tripCoordinates = [];
  List<LatLng> _smoothCoordinates = [];

  @override
  void initState() {
    super.initState();

    _tripCoordinates = widget.tripData.map<LatLng>((point) {
      double lat = point['latitude'];
      double lng = point['longitude'];
      return LatLng(lat, lng);
    }).toList();

    _drawSmoothPolyline();
  }

  Future<void> _drawSmoothPolyline() async {
    if (_tripCoordinates.isEmpty) return;

    String path = _tripCoordinates
        .map((point) => '${point.latitude}, ${point.longitude}')
        .join('|');

    const String apiKey = 'AIzaSyDUXyVASgZtmw4g1BYQyDNj0J0s7_3Dyjo';

    String url =
        "https://roads.googleapis.com/v1/snapToRoads?path=$path&interpolate=true&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['snappedPoints'] != null) {
          setState(() {
            _smoothCoordinates =
                (jsonResponse['snappedPoints'] as List).map((point) {
              var location = point['location'];
              return LatLng(location['latitude'], location['longitude']);
            }).toList();
          });
        }
      } else {
        print('Failed to snao roads: ${response.body}');
      }
    } catch (e) {
      print('error calling roads api: $e');
    }
  }

  Polyline _createPolyline(List<LatLng> points) {
    return Polyline(
      polylineId: PolylineId("route"),
      color: Colors.blue,
      points: points,
      width: 5,
      jointType: JointType.round,
      endCap: Cap.roundCap,
      startCap: Cap.roundCap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Route'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
            target: _tripCoordinates.isNotEmpty
                ? _tripCoordinates[0]
                : LatLng(0, 0),
            zoom: 14.0),
        polylines: {
          _createPolyline(_smoothCoordinates.isNotEmpty
              ? _smoothCoordinates
              : _tripCoordinates),
        },
        markers: _tripCoordinates
            .map((coord) => Marker(
                markerId: MarkerId('${coord.latitude}-${coord.longitude}'),
                position: coord))
            .toSet(),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
