import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  final String _firestoreUrl = 'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents';

  Future<void> updateUserRole(String email, String idToken, String role) async {
    final String url = '$_firestoreUrl/users/$email';
    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'fields': {
        'role': {'stringValue': role}
      }
    });

    final response = await http.patch(Uri.parse(url), headers: headers, body: body);
    if (response.statusCode != 200) {
      throw Exception('Failed to update role');
    }
  }

  Future<Map<String, dynamic>> fetchUserInfo(String idToken, String email) async {
    final String url = '$_firestoreUrl/users/$email';
    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user info');
    }
  }
}
