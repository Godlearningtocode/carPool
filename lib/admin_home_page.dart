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
  bool isLoading = false;

  final VehicleManager _vehicleManager = VehicleManager();

  @override
  void dispose() {
    _registrationController.dispose();
    _driverController.dispose();
    super.dispose();
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
        title: Text('Admin Dashboard'),
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
            TextFormField(
              controller: _registrationController,
              decoration:
                  InputDecoration(labelText: 'Vehicle registration number'),
            ),
            TextFormField(
              controller: _driverController,
              decoration: InputDecoration(labelText: 'Driver name'),
            ),
            SizedBox(
              height: 20,
            ),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () {
                      if (appState.idToken != null) {
                        _handleAddOrUpdateVehicle(context, appState.idToken!);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error: user is not signedin')));
                      }
                    },
                    child: Text('Add or update vehicle')),
            SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }
}
