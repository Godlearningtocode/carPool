// location_task_handler.dart
import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:car_pool/services/trip_service.dart';

class LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSubscription;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Initialize location services or other necessary services here
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, stop the service
      FlutterForegroundTask.stopService();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, stop the service
        FlutterForegroundTask.stopService();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, stop the service
      FlutterForegroundTask.stopService();
      return;
    }

    // Start listening to location updates
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      // Handle the location update
      TripService.handleLocationUpdate(position);
    });
  }

  Future<void> onEvent(DateTime timestamp, TaskStarter starter) async {
    // Handle periodic events if needed
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // Clean up resources
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void onButtonPressed(String id) {
    // Handle notification button presses if any
  }

  @override
  void onNotificationPressed() {
    // Handle notification press
  }
  
  @override
  void onRepeatEvent(DateTime timestamp) {
    // TODO: implement onRepeatEvent
  }
}
