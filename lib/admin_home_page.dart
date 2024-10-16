import 'package:car_pool/booking.dart';
import 'package:car_pool/driver_home_page.dart';
import 'package:car_pool/driver_trip_history.dart';
import 'package:car_pool/vehicle_management_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'my_app_state.dart';
import 'vehicle_manager.dart';

class AdminHomePage extends StatefulWidget {
  @override
  _adminHomePageState createState() => _adminHomePageState();
}

class _adminHomePageState extends State<AdminHomePage> {
  final TextEditingController _registrationController = TextEditingController();
  final TextEditingController _driverController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  bool isLoading = false;

  final VehicleManager _vehicleManager = VehicleManager();

  @override
  void dispose() {
    _registrationController.dispose();
    _driverController.dispose();
    super.dispose();
  }

  Future<void> _promoteRoDriver(String email, String idToken) async {
    var appState = Provider.of<MyAppState>(context, listen: false);
    try {
      await appState.updateUserRoleToDriver(email, idToken);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$email has been promoted to driver')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to promote to driver')));
    }
  }

  Future<void> _promoteToAdmin(String email, String idToken) async {
    var appState = Provider.of<MyAppState>(context, listen: false);
    try {
      await appState.updateUserRoleToAdmin(email, idToken);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$email has been promoted to admin')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('failed to promote to admin: $e')));
    }
  }

  Future<void> _handleAddOrUpdateVehicle(
      BuildContext context, String idToken) async {
    setState(() {
      isLoading = true;
    });

    try {
      await _vehicleManager.addOrUpdateVehicleStatus(idToken,
          _registrationController.text.trim(), _driverController.text.trim());

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehicle added/updated succesfully')),
      );

      _registrationController.clear();
      _driverController.clear();
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: failed to add update vehicle')));
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<MyAppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Home'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                  labelText: 'Email of user to promote',
                  hintText: 'Enter user email'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_emailController.text.isNotEmpty) {
                      _promoteRoDriver(
                          _emailController.text.trim(), appState.idToken!);
                    }
                  },
                  child: Text('Promote to driver'),
                ),
                ElevatedButton(
                    onPressed: () {
                      if (_emailController.text.isNotEmpty) {
                        _promoteToAdmin(
                            _emailController.text.trim(), appState.idToken!);
                      }
                    },
                    child: Text('Promote to admin')),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DriverTripHistoryPage()));
                },
                child: Text('View driver trip history')),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RideBookingPage()));
                },
                child: Text('Book a ride')),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DriverHomePage()));
                },
                child: Text('Start Trip')),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => VehicleManagementPage()));
                },
                child: Text('Add or update Vehicles')),
          ],
        ),
      ),
    );
  }
}
