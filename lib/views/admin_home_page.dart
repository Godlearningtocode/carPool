import 'package:car_pool/services/vehicle_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:car_pool/providers/my_app_state.dart';

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final TextEditingController _registrationController = TextEditingController();
  final TextEditingController _driverController = TextEditingController();
  bool isLoading = false;

  final VehicleManager _vehicleManager =
      VehicleManager(); // Use vehicle manager

  @override
  void dispose() {
    _registrationController.dispose();
    _driverController.dispose();
    super.dispose();
  }

  Future<void> _handleAddOrUpdateVehicle(String idToken) async {
    setState(() {
      isLoading = true;
    });

    try {
      await _vehicleManager.addOrUpdateVehicleStatus(
        idToken,
        _registrationController.text.trim(),
        _driverController.text.trim(),
      );

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehicle added/updated successfully')),
      );

      _registrationController.clear();
      _driverController.clear();
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: failed to add/update vehicle')),
      );
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
            // UI for managing vehicles, using the _vehicleManager instance
            TextField(
              controller: _registrationController,
              decoration: InputDecoration(
                labelText: 'Vehicle Registration',
                hintText: 'Enter registration number',
              ),
            ),
            TextField(
              controller: _driverController,
              decoration: InputDecoration(
                labelText: 'Driver',
                hintText: 'Enter driver name',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _handleAddOrUpdateVehicle(appState.idToken!);
              },
              child: isLoading
                  ? CircularProgressIndicator()
                  : Text('Add or Update Vehicle'),
            ),
          ],
        ),
      ),
    );
  }
}
