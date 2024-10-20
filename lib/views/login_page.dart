import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/my_app_state.dart';
import '../services/user_service.dart';
import 'admin_home_page.dart';
import 'driver_home_page.dart';
import 'home_page.dart';
import 'sign_up_page.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedRole = 'user';
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    var appState = Provider.of<MyAppState>(context, listen: false);

    if (_formKey.currentState!.validate()) {
      try {
        await appState.signIn(_emailController.text.trim(), _passwordController.text);

         if (appState.idToken == null) {
        throw Exception('ID token is null after sign in');
      }

        final idToken = appState.idToken!;
        final userId = _emailController.text.trim();

        Map<String, dynamic> userInfo = await UserService.fetchUserInfo(idToken: idToken, userId: userId);
        final userRole = userInfo['role'];

        if (userRole == _selectedRole) {
          appState.initializeVehicle([userId]);
          _navigateBasedOnRole(userRole);
        } else {
          _showErrorSnackbar('Incorrect role selection. Please select the correct role');
          appState.signOut();
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _navigateBasedOnRole(String userRole) {
    if (!mounted) return;
    switch (userRole) {
      case 'driver':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DriverHomePage()));
        break;
      case 'admin':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminHomePage()));
        break;
      default:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage()));
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Select Login Type', style: TextStyle(color: Colors.white, fontSize: 24)),
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign In')),
      drawer: _buildDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_errorMessage != null)
                Text(_errorMessage!, style: TextStyle(color: Colors.red)),
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
              ElevatedButton(
                onPressed: () async {
                  await _login();
                },
                child: Text('Log in as $_selectedRole'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpPage()));
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
