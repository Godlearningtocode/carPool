// ignore_for_file: use_build_context_synchronously

import 'package:car_pool/driver_home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'my_app_state.dart';

class SignUpPage extends StatefulWidget {
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Form key to validate form inputs
  final _formKey = GlobalKey<FormState>();

  // Controllers for the email and password input fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedRole = 'user';

  // Future to track the state of the sign-up process
  Future<void>? _futureSignUp;

  // Variable to hold any error messages
  String? _errorMessage;

  // Lifecycle method to dispose resources
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Method to handle the sign-up and sign-in process
  Future<void> signup(BuildContext context) async {
    // Access the MyAppState instance from Provider
    var appState = Provider.of<MyAppState>(context, listen: false);

    try {
      print('signing up user 48 signuppage');
      // Perform sign-up and sign-in actions
      await appState.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _phoneNumberController.text.trim(),
        _addressController.text.trim(),
        _selectedRole,
      );

      print('signin in user 58 signuppage');
      await appState.signIn(
          _emailController.text.trim(), _passwordController.text);

      if (!mounted) return;

      print('signed in user 64 signuppage');
      // Show a success message
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Sign-Up successful!')));

      // Navigate to the home page after successful sign-up and sign-in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                appState.role == 'driver' ? DriverHomePage() : MyHomePage()),
      );
    } catch (e) {
      // Update the error message in the UI
      setState(() {
        _errorMessage = e.toString();
      });

      // Show a failure message using a Snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-Up failed: $e')),
      );
    }
  }

  // Build method to construct the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Display error message if available
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),

                // Email input field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    // Basic email validation
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'.+@.+\..+').hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),

                // Password input field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    // Basic password validation
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(labelText: 'First Name'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your first name' : null,
                ),

                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(labelText: 'Last Name'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your last name' : null,
                ),

                TextFormField(
                  controller: _phoneNumberController,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your phone number' : null,
                ),

                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: 'Address'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your address' : null,
                ),

                SizedBox(height: 20),

                DropdownButtonFormField(
                  value: _selectedRole,
                  decoration: InputDecoration(labelText: 'Select Role'),
                  items: [
                    DropdownMenuItem(
                      value: 'user',
                      child: Text('User'),
                    ),
                    DropdownMenuItem(
                      value: 'driver',
                      child: Text('Driver'),
                    )
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a role';
                    }
                    return null;
                  },
                ),

                SizedBox(
                  height: 20,
                ),

                // FutureBuilder to manage the state of the sign-up process
                FutureBuilder<void>(
                  future: _futureSignUp,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.red));
                    }

                    // Sign-Up button
                    return ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          setState(() {
                            _futureSignUp = signup(context);
                          });
                        }
                      },
                      child: Text('Sign Up'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
