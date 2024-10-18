import 'package:car_pool/services/ride_booking_service.dart';
import 'package:car_pool/views/location_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:car_pool/providers/my_app_state.dart';

class RideBookingPage extends StatefulWidget {
  @override
  RideBookingPageState createState() => RideBookingPageState();
}

class RideBookingPageState extends State<RideBookingPage> {
  final TextEditingController _destinationController = TextEditingController();
  String? _bookingMessage;
  String? _selectedVehicle;
  List<Map<String, dynamic>> availableVehicles = [];
  List<Map<String, dynamic>> autoCompleteSuggestions = [];
  String? _selectedPlaceId;
  final RideBookingService _rideBookingService = RideBookingService();

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _fetchVehicles(String idToken) async {
    try {
      final vehicles = await _rideBookingService.fetchVehicles(idToken);
      setState(() {
        availableVehicles = vehicles;
      });
    } catch (e) {
      print('Error fetching vehicles: $e');
    }
  }

  Future<void> _fetchAutoCompleteSuggestions(String input) async {
    try {
      final suggestions = await _rideBookingService.fetchAutoCompleteSuggestions(input);
      setState(() {
        autoCompleteSuggestions = suggestions;
      });
    } catch (e) {
      print('Error fetching suggestions: $e');
    }
  }

  Future<void> _updateVehicleAfterBooking(String idToken, String registrationNumber, String passengerName) async {
    try {
      await _rideBookingService.updateVehicleAfterBooking(idToken, registrationNumber, passengerName);
      setState(() {
        _bookingMessage = 'Seat booked successfully';
      });
    } catch (e) {
      setState(() {
        _bookingMessage = 'Error booking seat: $e';
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var appState = Provider.of<MyAppState>(context, listen: false);
    if (appState.idToken != null) {
      _fetchVehicles(appState.idToken!);
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<MyAppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Book a ride'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(labelText: 'Destination'),
                onChanged: _fetchAutoCompleteSuggestions,
              ),
              if (autoCompleteSuggestions.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: autoCompleteSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = autoCompleteSuggestions[index];
                    return ListTile(
                      title: Text(suggestion['description']),
                      onTap: () {
                        _destinationController.text = suggestion['description'];
                        _selectedPlaceId = suggestion['placeId'];
                        setState(() {
                          autoCompleteSuggestions = [];
                        });
                      },
                    );
                  },
                ),
              DropdownButton<String>(
                hint: Text('Select a vehicle'),
                value: _selectedVehicle,
                items: availableVehicles.map((vehicle) {
                  return DropdownMenuItem<String>(
                    value: vehicle['registrationNumber'],
                    child: Text(
                        '${vehicle['driverName']} ${vehicle['registrationNumber']} - ${vehicle['availableSeats']} seats left'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedVehicle = value;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_selectedVehicle == null || _destinationController.text.isEmpty) {
                    setState(() {
                      _bookingMessage = 'Please select a vehicle and enter a destination';
                    });
                  } else {
                    await _updateVehicleAfterBooking(
                        appState.idToken!, _selectedVehicle!, appState.userFullName!);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPage(
                          destination: _destinationController.text,
                          placeId: _selectedPlaceId!,
                        ),
                      ),
                    );
                  }
                },
                child: Text('Book seat'),
              ),
              if (_bookingMessage != null)
                Text(
                  _bookingMessage!,
                  style: TextStyle(
                      color: _bookingMessage == 'Seat booked successfully'
                          ? Colors.green
                          : Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
