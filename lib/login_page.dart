import 'package:car_pool/admin_home_page.dart';
import 'package:car_pool/handle_user_info.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'my_app_state.dart';
import 'sign_up_page.dart';
import 'driver_home_page.dart'; // Import driver home page

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Controllers for email and password input
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedRole = 'user';

  // Variable to store error message
  String? _errorMessage;

  // Lifecycle method to dispose of controllers
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper method to handle login
  Future<void> _login() async {
    var appState = Provider.of<MyAppState>(context, listen: false);

    if (_formKey.currentState!.validate()) {
      try {
        print('entering signin 41 loginPage');
        await appState.signIn(_emailController.text.trim(), _passwordController.text);
        print('signin completed 43 loginPage');

        if(appState.idToken == null) {
          throw Exception('ID token is null after sign in 46 loginPage');
        }

        String idToken = appState.idToken!;
        String userId = _emailController.text.trim();
        Map<String, dynamic> userInfo = await fetchUserInfo(idToken, userId);

        print('fetched user info 49 login page');

        String userRole = userInfo['role'];
        print(userRole);
        if (userRole == _selectedRole) {
          appState.updateUserRole(userRole);

          appState.initializeVehicle([_emailController.text.trim()]);

          print('initialized vehicles 54 loginPage');

          if (!mounted) return;
          print(userRole);
          if (userRole == 'driver') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => DriverHomepage()));
          } else if (userRole == 'admin') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => AdminHomePage()));
          } else {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => MyHomePage()));
          }
        } else {
          setState(() {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Incorrect role selection. Please select the correct role')));
          });
          appState.signOut();
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Select Login Type',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('User Login'),
            onTap: () {
              setState(() {
                _selectedRole = 'user';
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.admin_panel_settings),
            title: Text('Admin Login'),
            onTap: () {
              setState(() {
                _selectedRole = 'admin';
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.drive_eta),
            title: Text('Driver Login'),
            onTap: () {
              setState(() {
                _selectedRole = 'driver';
              });
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  // Build method to construct the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
      ),
      drawer: _buildDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Display error message if present
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
                  if (value == null || value.isEmpty) {
                    return 'Please enter your Email';
                  }
                  if (!RegExp(r'.+@.+\..+').hasMatch(value)) {
                    return 'Enter a valid Email';
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
                  if (value == null || value.isEmpty) {
                    return 'Please enter your Password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              SizedBox(height: 20),

              // Sign In button
              ElevatedButton(
                onPressed: () async {
                  await _login();
                },
                child: Text('Log in as $_selectedRole'),
              ),

              // Sign Up button for users without an account
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpPage()),
                  );
                },
                child: Text('Don\'t have an account? Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
