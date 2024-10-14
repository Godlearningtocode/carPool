import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> uploadUserInfo(
    String idToken,
    String userId,
    String email,
    String firstName,
    String lastName,
    String phoneNumber,
    String address,
    String role) async {
  final url =
      'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/users?documentId=$userId';

  final headers = {
    'Authorization': 'Bearer $idToken',
    'Content-Type': 'application/json'
  };

  final body = jsonEncode({
    'fields': {
      'email': {'stringValue': email},
      'firstName': {'stringValue': firstName},
      'lastName': {'stringValue': lastName},
      'phoneNumber': {'stringValue': phoneNumber},
      'address': {'stringValue': address},
      'role': {
        'stringValue': role,
      }
    },
  });

  try {
    final response =
        await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode == 200) {
      print('user info uploaded succesfully 47 handle user info');
    } else {
      print('failed to upload user info: ${response.body} 49 handleUserInfo');
      throw Exception('Error: ${response.body}');
    }
  } catch (e) {
    print('Error uploading user info: $e');
    throw e;
  }
}

Future<Map<String, dynamic>> fetchUserInfo(
    String idToken, String userId) async {
  final url =
      'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/users/$userId';

  final headers = {
    'Authorization': 'Bearer $idToken',
    'Content-Type': 'application/json'
  };

  try {
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final userInfo = {
        'email': data['fields']?['email']?['stringValue'] ?? '',
        'firstname': data['fields']?['firstName']?['stringValue'] ?? '',
        'lastName': data['fields']?['lastName']?['stringValue'] ?? '',
        'phoneNumber': data['fields']?['phoneNumber']?['stringValue'] ?? '',
        'address': data['fields']?['address']?['stringValue'] ?? '',
        'role': data['fields']?['role']?['stringValue'] ?? 'user',
      };

      return userInfo;
    } else {
      print('failed to fetch user info: ${response.body}');
      throw Exception('Error: ${response.body}');
    }
  } catch (e) {
    print('Error fetching user info: $e');
    throw e;
  }
}
