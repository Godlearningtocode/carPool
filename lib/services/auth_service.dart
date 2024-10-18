import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String apiKey = 'AIzaSyC3gOJDyIviVzsjmfqOR66CzIjiVn8U2z8';
  final String _authUrl = 'https://identitytoolkit.googleapis.com/v1';

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final String url = '$_authUrl/accounts:signInWithPassword?key=$apiKey';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to sign in: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> signUp(String email, String password) async {
    final String url = '$_authUrl/accounts:signUp?key=$apiKey';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to sign up: ${response.body}');
    }
  }
}
