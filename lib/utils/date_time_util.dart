import 'package:intl/intl.dart';

class DateTimeUtil {
  // Converts a DateTime string to a Firestore-compatible timestamp
  static String convertToFirestoreTimestamp(String dateTime) {
    DateTime parsedDate = DateTime.parse(dateTime).toUtc();
    return parsedDate.toIso8601String();
  }

  // Formats a DateTime for displaying
  static String formatDateTime(String timestamp) {
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      print('Invalid timestamp: $timestamp');
      return "Invalid date";
    }
  }
}
