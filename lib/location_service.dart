import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static StreamSubscription<Position>? _positionSubscription;
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> startLocationTracking(
      {required Function(Position) onPositionUpdate}) async {
    const androidSettings = AndroidInitializationSettings(
        'app_icon'); // Ensure 'app_icon.png' is in `res/drawable`

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    const androidNotificationDetails = AndroidNotificationDetails(
      'location_channel',
      'Location Tracking',
      channelDescription: 'Car Pool tracking your trip',
      importance: Importance.low,
      priority: Priority.low,
      showWhen: false,
    );

    const platformNotificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    // Show notification to keep service alive
    await _notificationsPlugin.show(
      0,
      'Trip in Progress',
      'Car Pool is tracking your location.',
      platformNotificationDetails,
    );

    // Start location updates
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      onPositionUpdate(position);
    });
  }

  static void stopLocationTracking() {
    _positionSubscription?.cancel();
    _notificationsPlugin.cancel(0); // Remove the foreground notification
  }
}
