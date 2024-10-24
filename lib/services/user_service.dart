import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  // Firebase Identity Toolkit API URL for signing up users
  static const String _signUpUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyC3gOJDyIviVzsjmfqOR66CzIjiVn8U2z8';
  // Firestore base URL for user-related operations
  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/users';

  /// Signs up a new user using Firebase Authentication and uploads additional information to Firestore.
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String address,
    required String role,
  }) async {
    try {
      // Sign-up API call to Firebase
      final response = await http.post(
        Uri.parse(_signUpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String idToken = jsonResponse['idToken'];
        String localId = jsonResponse['localId'];

        // Upload additional user information to Firestore
        await uploadUserInfo(
          idToken: idToken,
          userId: localId,
          email: email,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          address: address,
          role: role,
        );

        if (role == 'driver') {
          final driverResponse = await http.post(
            Uri.parse('http://192.168.1.2:3000/api/create-driver'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization':
                  'Bearer $idToken', // Optional: Send token for authorization
            },
            body: jsonEncode({
              'driverName': '$firstName $lastName',
              'driverId': localId, // Use Firebase UID as driverId
            }),
          );

          if (driverResponse.statusCode == 200) {
            print('Driver document created successfully in MongoDB.');
          } else {
            print('Failed to create driver document: ${driverResponse.body}');
          }
        }
      } else {
        throw Exception('Failed to sign up: ${response.body}');
      }
    } catch (e) {
      throw Exception('Sign-up failed: $e');
    }
  }

  /// Uploads user information to Firestore.
  static Future<void> uploadUserInfo({
    required String idToken,
    required String userId,
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String address,
    required String role,
  }) async {
    final url = '$_baseUrl?documentId=$userId';

    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'fields': {
        'email': {'stringValue': email},
        'firstName': {'stringValue': firstName},
        'lastName': {'stringValue': lastName},
        'phoneNumber': {'stringValue': phoneNumber},
        'address': {'stringValue': address},
        'role': {'stringValue': role},
      },
    });

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode != 200) {
        throw Exception('Failed to upload user info: ${response.body}');
      } else {
        print('User info uploaded successfully.');
      }
    } catch (e) {
      throw Exception('Error uploading user info: $e');
    }
  }

  Future<void> createDriverDocument(
      {required String idToken,
      required String driverName,
      required String uid}) async {
    final url =
        'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/DriverTrip/$driverName';

    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'fields': {
        'driverId': {'stringValue': uid},
        'driverName': {'stringValue': driverName},
      }
    });

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode != 200) {
        throw Exception('Failed to create driver document: ${response.body}');
      } else {
        print('Driver document created successfully.');
      }
    } catch (e) {
      throw Exception('Error creating driver document: $e');
    }
  }

  Future<void> createDriverTripsSubCollection(
      {required String idToken,
      required String driverName,
      required String uid}) async {
    final url =
        'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/DriverTrip/$driverName/trips/$uid';

    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'fields': {
        'driverId': {'stringValue': uid},
        'driverName': {'stringValue': driverName},
      }
    });

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode != 200) {
        throw Exception(
            'failed to create driver trips subcollection: ${response.body}');
      } else {
        print('Driver trips subcolelction crwated succesfully');
      }
    } catch (e) {
      throw Exception('Error creating trips subcolelction: $e');
    }
  }

  /// Fetches user information from Firestore.
  static Future<Map<String, dynamic>> fetchUserInfo({
    required String idToken,
    required String userId,
  }) async {
    final url = '$_baseUrl/$userId';

    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final email = data['fields']?['email']?['stringValue'] ?? '';
        final firstName = data['fields']?['firstName']?['stringValue'] ?? '';
        final lastName = data['fields']?['lastName']?['stringValue'] ?? '';
        final phoneNumber =
            data['fields']?['phoneNumber']?['stringValue'] ?? '';
        final address = data['fields']?['address']?['stringValue'] ?? '';
        final role = data['fields']?['role']?['stringValue'] ?? 'user';

        // If role is driver, combine firstName and lastName without spaces
        final driverName = (role == 'driver') ? '$firstName$lastName' : '';

        return {
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber,
          'address': address,
          'role': role,
          'driverName': driverName,
        };
      } else {
        throw Exception('Failed to fetch user info: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching user info: $e');
    }
  }

  /// Updates user role in Firestore.
  static Future<void> updateUserRole({
    required String email,
    required String idToken,
    required String role,
  }) async {
    final String url = '$_baseUrl/$email';

    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'fields': {
        'role': {'stringValue': role}
      }
    });

    try {
      final response =
          await http.patch(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode != 200) {
        throw Exception('Failed to update role: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating role: $e');
    }
  }

  /// Fetches user information by email from Firestore.
  static Future<Map<String, dynamic>> fetchUserInfoByEmail({
    required String idToken,
    required String email,
  }) async {
    final String url = '$_baseUrl/$email';

    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch user info: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching user info: $e');
    }
  }
}
