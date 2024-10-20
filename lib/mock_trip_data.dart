// mock_trip_data.dart
import 'package:intl/intl.dart';

// Mock trip data for testing
List<Map<String, dynamic>> getMockTripData() {
  return [
    {
      'latitude': 37.7749,
      'longitude': -122.4194,
      'timeStamp': DateFormat('yyyy-MM-ddTHH:mm:ss').format(DateTime.now().subtract(Duration(minutes: 10))),
    },
    {
      'latitude': 37.7750,
      'longitude': -122.4183,
      'timeStamp': DateFormat('yyyy-MM-ddTHH:mm:ss').format(DateTime.now().subtract(Duration(minutes: 8))),
    },
    {
      'latitude': 37.7751,
      'longitude': -122.4172,
      'timeStamp': DateFormat('yyyy-MM-ddTHH:mm:ss').format(DateTime.now().subtract(Duration(minutes: 5))),
    },
    {
      'latitude': 37.7752,
      'longitude': -122.4161,
      'timeStamp': DateFormat('yyyy-MM-ddTHH:mm:ss').format(DateTime.now()),
    },
  ];
}
