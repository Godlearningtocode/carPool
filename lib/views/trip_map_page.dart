// trip_map_page.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:car_pool/services/roads_service.dart';

class TripMapPage extends StatefulWidget {
  final List tripData;

  TripMapPage({required this.tripData});

  @override
  _TripMapPageState createState() => _TripMapPageState();
}

class _TripMapPageState extends State<TripMapPage> {
  // ignore: unused_field
  GoogleMapController? _mapController;
  List<LatLng> _tripCoordinates = [];
  List<LatLng> _smoothCoordinates = [];
  final RoadsService _roadsService = RoadsService();

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

    List<LatLng> snappedCoordinates =
        await _roadsService.snapToRoads(_tripCoordinates);
    setState(() {
      _smoothCoordinates = snappedCoordinates.isNotEmpty
          ? snappedCoordinates
          : _tripCoordinates;
    });
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
          _createPolyline(
              _smoothCoordinates.isNotEmpty ? _smoothCoordinates : _tripCoordinates),
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
