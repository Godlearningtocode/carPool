import 'package:car_pool/providers/my_app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'vehicle_manager.dart'; // Assuming the vehicle manager is in this file

class VehicleManagementPage extends StatefulWidget {
  @override
  _VehicleManagementPageState createState() => _VehicleManagementPageState();
}

class _VehicleManagementPageState extends State<VehicleManagementPage> {
  final TextEditingController _registrationController = TextEditingController();
  final TextEditingController _driverController = TextEditingController();
  bool isLoading = false;

  final VehicleManager _vehicleManager =
      VehicleManager(); // Manage vehicle status

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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle added/updatess successfully')),
        );
      }

      _registrationController.clear();
      _driverController.clear();
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: failed to add/update vehicle')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<MyAppState>(context);

    return Scaffold(
        appBar: AppBar(
          title: Text('Add or Update Vehicle'),
        ),
        body: SingleChildScrollView(
          child: Padding(
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
                            _handleAddOrUpdateVehicle(
                                context, appState.idToken!);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Error: user is not signed in')),
                            );
                          }
                        },
                        child: Text('Add or update Vehicle'),
                      ),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ));
  }
}
