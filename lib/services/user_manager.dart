import 'package:http/http.dart' as http;
import 'dart:convert';

class UserManager {
  Future<void> promoteToDriver(String email, String idToken) async {
    final url = 'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/users/$email';
    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'fields': {
        'role': {'stringValue': 'driver'}
      }
    });

    final response = await http.patch(Uri.parse(url), headers: headers, body: body);
    if (response.statusCode != 200) {
      throw Exception('Failed to promote to driver');
    }
  }

  Future<void> promoteToAdmin(String email, String idToken) async {
    final url = 'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/users/$email';
    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'fields': {
        'role': {'stringValue': 'admin'}
      }
    });

    final response = await http.patch(Uri.parse(url), headers: headers, body: body);
    if (response.statusCode != 200) {
      throw Exception('Failed to promote to admin');
    }
  }
}
