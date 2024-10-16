// ignore_for_file: unused_field, prefer_const_declarations

import 'package:car_pool/booking.dart';
import 'package:car_pool/handle_user_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

// State management class for authentication and user state
class MyAppState extends ChangeNotifier {
  String? _userEmail;
  String? _idToken;
  String? _refreshToken;
  String? _firstName;
  String? _lastName;
  String? _phoneNumber;
  String? _address;
  String? _userRole;
  String? _role;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isAdmin = false;

  List<Vehicle> vehicles = [];
  String? get idToken => _idToken;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get userRole => _userRole;
  String? get role => _role;

  Future<void> updateUserRoleToDriver(String email, String idToken) async {
    final url =
        'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/users/$email';

    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'fields': {
        'role': {'stringValue': 'driver'}
      }
    });

    final response =
        await http.patch(Uri.parse(url), headers: headers, body: body);
    if (response.statusCode != 200) {
      throw Exception('Failed to promote to driver');
    }
  }

  Future<void> updateUserRoleToAdmin(String email, String idToken) async {
    final url =
        'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/users/$email';
    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'fields': {
        'role': {'stringValue': 'admin'}
      }
    });

    final response =
        await http.patch(Uri.parse(url), headers: headers, body: body);
    if (response.statusCode != 200) {
      throw Exception('Failed to promote to admin');
    }
  }

  void initializeVehicle(List<String> registrationNumbers) {
    vehicles = registrationNumbers
        .map((regNum) =>
            Vehicle(registrationNumber: regNum, driver: 'Driver for $regNum'))
        .toList();
    notifyListeners();
  }

  bool bookSeatInVehicle(String registrationNumber, String passengerName) {
    Vehicle? vehicle;

    try {
      vehicle = vehicles
          .firstWhere((v) => v.registrationNumber == registrationNumber);
    } catch (e) {
      return false;
    }

    if (vehicle.bookSeat(passengerName)) {
      notifyListeners();
      return true;
    }

    return false;
  }

  int getAvailableSeats(String registrationNumber) {
    Vehicle? vehicle;

    try {
      vehicle = vehicles
          .firstWhere((v) => v.registrationNumber == registrationNumber);
    } catch (e) {
      return 0;
    }

    return vehicle.availableSeats;
  }

  bool isVehicleFull(String registrationNumber) {
    Vehicle? vehicle;

    try {
      vehicle = vehicles
          .firstWhere((v) => v.registrationNumber == registrationNumber);
    } catch (e) {
      return true;
    }

    return vehicle.isFull;
  }

  List<Vehicle> get availableVehicles => vehicles;

  // Constructor that listens for authentication state changes
  MyAppState() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _checkAdminStatus(user);
      }
      notifyListeners();
    });
  }

  bool get isAdmin => _isAdmin;

  // Getters
  User? get user => _user;
  String? get userEmail => _userEmail;
  bool get isLoggedIn => _user != null;

  void updateUserRole(String role) {
    _userRole = role;
    notifyListeners();
  }

  // Sign-out method to clear user data and notify listeners
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _userEmail = null;
    _idToken = null;
    _refreshToken = null;
    notifyListeners();
  }

  // Sign-in method using REST API
  Future<void> signIn(String email, String password) async {
    const String apiKey = 'AIzaSyC3gOJDyIviVzsjmfqOR66CzIjiVn8U2z8';
    final String url =
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey';

    try {
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
        // ignore: unused_local_variable
        final jsonResponse = jsonDecode(response.body);
        _userEmail = jsonResponse['email'];
        _idToken = jsonResponse['idToken'];
        _refreshToken = jsonResponse['refreshToken'];

        final userInfo = await fetchUserInfo(_idToken!, _userEmail!);

        _firstName = userInfo['firstName'];
        _lastName = userInfo['lastName'];
        _role = userInfo['role'];

        notifyListeners();
      } else {
        final errorResponse = jsonDecode(response.body);
        throw Exception(
            'Failed to sign in: ${errorResponse['error']['message']}');
      }
    } catch (e) {
      throw Exception('Sign-in failed via REST API');
    }
  }

  // Sign-up method using REST API
  Future<void> signUp(String email, String password, String firstName,
      String lastName, String phoneNumber, String address, String role) async {
    const String apiKey = 'AIzaSyC3gOJDyIviVzsjmfqOR66CzIjiVn8U2z8';
    final String signUpUrl =
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey';
    final String signInUrl =
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey';

    print('Entered sign-up method via REST API');

    try {
      print('signing up user 170 myappstate');
      final response = await http.post(
        Uri.parse(signUpUrl),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      print('decoding response from REST api 181 myappstate');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        _userEmail = jsonResponse['email'];
        _idToken = jsonResponse['idToken'];
        _refreshToken = jsonResponse['refreshToken'];

        print('uploading info to firebase database 189 myappstate');

        try {
          await uploadUserInfo(_idToken!, _userEmail!, email, firstName,
              lastName, phoneNumber, address, role);

          print('User info updated succesfully 194 myappstate');

          // Immediately sign in after sign-up
          final sigInResponse = await http.post(
            Uri.parse(signInUrl),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'returnSecureToken': true
            }),
          );

          print('decoding sign in reposne from rest api 217 myappstate');

          if (sigInResponse.statusCode == 200) {
            final signInJson = jsonDecode(sigInResponse.body);
            _userEmail = email;
            _idToken = signInJson['idToken'];
            _refreshToken = signInJson['refreshToken'];

            print('User signed in successfully');
            notifyListeners();
          } else {
            final errorResponse = jsonDecode(sigInResponse.body);
            throw Exception(
                'Failed to sign in: ${errorResponse['error']['message']}');
          }

          notifyListeners();
        } catch (e) {
          print('Error during upload or sign in: $e 226 myappstate');
          throw e;
        }
        notifyListeners();

        print('signing in user 205 myappstate');
      } else {
        final errorResponse = jsonDecode(response.body);
        throw Exception(
            'Failed to create user: ${errorResponse['error']['message']}');
      }
    } catch (e) {
      throw Exception('Sign-up failed via REST API');
    }
  }

  Future<void> addAdminUser(String email) async {
    if (_user!.email == 'shivamcodes01@gmail.com') {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'role': 'admin'});
      } else {
        print('No user found with email $email');
      }
    } else {
      print('Only the developer can add admin users.');
    }
  }

  Future<void> _checkAdminStatus(User user) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc['role'] == 'admin') {
        _isAdmin = true;
      } else {
        _isAdmin = false;
      }
    } catch (e) {
      print('Error checking admin status $e');
      _isAdmin = false;
    }
  }
}

// Home page UI showing user email if signed in
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<MyAppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Car Pool'),
        actions: [
          IconButton(
            onPressed: () async {
              appState.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: Icon(Icons.logout),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${appState.userEmail}!'),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RideBookingPage()),
                  );
                },
                child: Text('Book a ride')),
          ],
        ),
      ),
    );
  }
}

class Vehicle {
  final String registrationNumber;
  final String driver;
  final int maxPassengers = 4;
  List<String> passengers = [];

  Vehicle({required this.registrationNumber, required this.driver});

  int get availableSeats => maxPassengers - passengers.length;

  bool bookSeat(String passengerName) {
    if (passengers.length < maxPassengers) {
      passengers.add(passengerName);
      return true;
    } else {
      return false;
    }
  }

  bool get isFull => passengers.length >= maxPassengers;
}
