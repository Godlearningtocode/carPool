import 'dart:convert';

import 'package:car_pool/handle_user_info.dart';
import 'package:car_pool/models/vehicle_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:car_pool/services/auth_service.dart';
import 'package:car_pool/services/user_service.dart';
import 'package:http/http.dart' as http;

class MyAppState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  String? _userEmail;
  String? _idToken;
  String? _role;
  String? _driverName;
  String? _userFullName;
  String? _userRole;
  // ignore: unused_field
  String? _refreshToken;
  bool _isAdmin = false;

  User? _user;

  String? get userEmail => _userEmail;
  String? get idToken => _idToken;
  String? get role => _role;
  String? get driverName => _driverName;
  String? get userFullName => _userFullName;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _isAdmin;
  String? get userRole => _userRole;

  List<Vehicle> vehicles = [];

  // Sign-up method using REST API without immediate sign-in
Future<void> signUp(String email, String password, String firstName,
    String lastName, String phoneNumber, String address, String role) async {
  const String apiKey = 'AIzaSyC3gOJDyIviVzsjmfqOR66CzIjiVn8U2z8';
  // ignore: prefer_const_declarations
  final String signUpUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey';

  print('Entered sign-up method via REST API');

  try {
    print('signing up user');
    final response = await http.post(
      Uri.parse(signUpUrl),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      _userEmail = jsonResponse['email'];
      _idToken = jsonResponse['idToken'];
      _refreshToken = jsonResponse['refreshToken'];

      print('uploading info to firebase database');

      try {
        // Upload user information to the database
        await uploadUserInfo(_idToken!, _userEmail!, email, firstName,
            lastName, phoneNumber, address, role);

        print('User info updated successfully');

        // Provide feedback that the account has been created
        notifyListeners();

        // Intimate the user to sign in via login page
        throw Exception('Account created successfully. Please sign in.');
      } catch (e) {
        print('Error during info upload: $e');
        // ignore: use_rethrow_when_possible
        throw e;
      }
    } else {
      final errorResponse = jsonDecode(response.body);
      throw Exception('Failed to create user: ${errorResponse['error']['message']}');
    }
  } catch (e) {
    throw Exception('Sign-up failed via REST API');
  }
}


  Future<void> signIn(String email, String password) async {
    try {
      final response = await _authService.signIn(email, password);
      _userEmail = response['email'];
      _idToken = response['idToken'];

      final userInfo = await _userService.fetchUserInfo(_idToken!, _userEmail!);
      _role = userInfo['role'];

      if (_role == 'driver') {
        _driverName = '${userInfo['firstName']} ${userInfo['lastName']}';
      }

      _userFullName = '${userInfo['firstName']} ${userInfo['lastName']}';

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to sign in');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _userEmail = null;
    _idToken = null;
    _role = null;
    _refreshToken = null;
    notifyListeners();
  }

  Future<void> updateUserRole(String email, String role) async {
    try {
      await _userService.updateUserRole(email, _idToken!, role);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update role');
    }
  }

  void setDriverName(String name) {
    if (_role == 'driver') {
      _driverName = name;
      notifyListeners();
    }
  }

  void initializeVehicle(List<String> registrationNumbers) {
    vehicles = registrationNumbers
        .map((regNum) =>
            Vehicle(registrationNumber: regNum, driver: 'Driver for $regNum'))
        .toList();
    notifyListeners();
  }
}
