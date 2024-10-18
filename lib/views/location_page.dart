import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:car_pool/services/location_service.dart';

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
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Location permissions are permanently denied. Enable them from settings')));
      return;
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await _locationService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
        _currentLatLng = LatLng(position.latitude, position.longitude);
      });
      _fetchDestinationDetails(widget.placeId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _fetchDestinationDetails(String placeId) async {
    try {
      LatLng? destinationPosition = await _locationService.getDestinationDetails(placeId);
      if (destinationPosition != null) {
        setState(() {
          _destinationMarker = Marker(
              markerId: MarkerId('destination'),
              position: destinationPosition,
              infoWindow: InfoWindow(title: 'Destination', snippet: widget.destination));
        });
        if (_currentLatLng != null) {
          _drawRouteAndEta(_currentLatLng!, destinationPosition);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch destination details: $e')));
    }
  }

  Future<void> _drawRouteAndEta(LatLng start, LatLng end) async {
    try {
      final routeData = await _locationService.getRouteAndEta(start, end);
      var distanceMeters = routeData['distanceMeters'];
      var duration = routeData['duration'];
      var polylinePoints = routeData['polylinePoints'];

      List<LatLng> decodedPolyline = _locationService.decodePolyline(polylinePoints);

      double distanceKm = distanceMeters / 1000;
      String durationString = duration.toString().replaceAll('s', '');
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
                  start.latitude < end.latitude ? start.latitude : end.latitude,
                  start.longitude < end.longitude
                      ? start.longitude
                      : end.longitude),
              northeast: LatLng(
                  start.latitude > end.latitude ? start.latitude : end.latitude,
                  start.longitude > end.longitude
                      ? start.longitude
                      : end.longitude)),
          50.0));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error calculating route: $e')));
    }
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
