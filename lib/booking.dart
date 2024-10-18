import 'dart:convert';
import 'package:car_pool/providers/my_app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'location_page.dart';

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
  final String _placesApiKey = 'AIzaSyDUXyVASgZtmw4g1BYQyDNj0J0s7_3Dyjo';
  final String url =
      'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/vehicles';

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> fetchAutoCompleteSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        autoCompleteSuggestions = [];
      });
      return;
    }

    final String requestUrl =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_placesApiKey&types=geocode';

    try {
      final response = await http.get(Uri.parse(requestUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          autoCompleteSuggestions =
              data['predictions'].map<Map<String, dynamic>>((prediction) {
            return {
              'description': prediction['description'],
              'placeId': prediction['place_id'],
            };
          }).toList();
        });
      } else {
        print('Failed to fetch autocomplete suggestions');
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
    }
  }

  Future<void> fetchVehicles(String idToken) async {
    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-type': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print(jsonResponse['documents']);

        if (jsonResponse['documents'] != null) {
          final List<Map<String, dynamic>> vehicleList =
              (jsonResponse['documents'] as List).map((doc) {
            final registrationNumber = doc['fields']?['registrationNumber']
                    ?['stringValue'] ??
                'Unknown';
            print(registrationNumber);
            final passengersArray =
                doc['fields']?['passengers']?['arrayValue']?['values'] ?? [];
            print(passengersArray);
            final maxPassengers = int.tryParse(
                    doc['fields']?['maxPassengers']?['integerValue'] ?? '4') ??
                4;
            print(maxPassengers);

            final availableSeats = maxPassengers - passengersArray.length;

            return {
              'registrationNumber': registrationNumber,
              'availableSeats': availableSeats,
              'status': doc['fields']?['status']?['stringValue'] ?? 'unknown',
              'driverName':
                  doc['fields']?['driverName']?['stringValue'] ?? 'unknown',
            };
          }).toList();

          setState(() {
            availableVehicles = vehicleList;
          });
        } else {
          print('No vehicles data found');
        }
      } else {
        print('Error fetching data: ${response.body}');
      }
    } catch (e) {
      print('error fetching vehicles: $e');
    }
  }

  Future<void> updateVehicleAfterBooking(
      String idToken, String registrationNumber, String passengerName) async {
    final url =
        'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/vehicles/$registrationNumber?updateMask.fieldPaths=passengers';

    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    try {
      final vehicleUrl =
          'https://firestore.googleapis.com/v1/projects/car-pool-786eb/databases/(default)/documents/vehicles/$registrationNumber';
      final vehicleResponse =
          await http.get(Uri.parse(vehicleUrl), headers: headers);

      if (vehicleResponse.statusCode == 200) {
        final vehicleData = jsonDecode(vehicleResponse.body);
        final passengerArray = vehicleData['fields']?['passengers']
                ?['arrayValue']?['values'] ??
            [];

        final updatedPassengers = [
          ...passengerArray,
          {'stringValue': passengerName}
        ];

        final body = jsonEncode({
          'fields': {
            'passengers': {
              'arrayValue': {'values': updatedPassengers},
            },
            'maxPassengers': {
              'integerValue': vehicleData['fields']?['maxPassengers']
                      ?['integerValue'] ??
                  '4'
            }
          },
        });
        final response =
            await http.patch(Uri.parse(url), headers: headers, body: body);

        if (response.statusCode == 200) {
          print('Vehicle updated succesfully');
        } else {
          print('Error updating vehicle: ${response.body}');
          throw Exception('Failed to update vehicle');
        }
      } else {
        print('Error fetching vehicle: ${vehicleResponse.body}');
        throw Exception('Failed to fetch vehicle');
      }
    } catch (e) {
      print('Error updating vehicle: $e');
      rethrow;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    var appState = Provider.of<MyAppState>(context, listen: false);
    if (appState.idToken != null) {
      fetchVehicles(appState.idToken!);
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<MyAppState>(context);

    String userFullName = '${appState.userFullName}';

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
                  decoration: InputDecoration(
                    labelText: 'Destination',
                    hintText: 'Enter your destination',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (input) {
                    fetchAutoCompleteSuggestions(input);
                  },
                ),
                if (autoCompleteSuggestions.isNotEmpty)
                  Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: autoCompleteSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = autoCompleteSuggestions[index];
                        return ListTile(
                          title: Text(suggestion['description']),
                          onTap: () {
                            _destinationController.text =
                                suggestion['description'];
                            _selectedPlaceId = suggestion['placeId'];
                            setState(() {
                              autoCompleteSuggestions = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Text('Select a vehicle'),
                        value: _selectedVehicle,
                        items: availableVehicles.map((vehicle) {
                          // Use 'vehicle'
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
                    )
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                    onPressed: () async {
                      if (_selectedVehicle == null) {
                        setState(() {
                          _bookingMessage = 'Please select a vehicle';
                        });
                      } else if (availableVehicles.firstWhere((vehicle) =>
                              vehicle['registrationNumber'] ==
                              _selectedVehicle)['availableSeats'] ==
                          0) {
                        setState(() {
                          _bookingMessage =
                              'Sorry, No more seats are available in this vehicle';
                        });
                      } else if (_destinationController.text.isEmpty) {
                        setState(() {
                          _bookingMessage = 'Please enter a destination';
                        });
                      } else {
                        try {
                          await updateVehicleAfterBooking(appState.idToken!,
                              _selectedVehicle!, userFullName);

                          setState(() {
                            _bookingMessage = 'Seat booked successfully';
                          });

                          fetchVehicles(appState.idToken!);

                          Navigator.push(
                            // ignore: use_build_context_synchronously
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationPage(
                                destination: _destinationController.text,
                                placeId: _selectedPlaceId!,
                              ),
                            ),
                          );
                        } catch (e) {
                          setState(() {
                            _bookingMessage = 'Error booking seat $e';
                          });
                        }
                      }
                    },
                    child: Text('Book seat')),
                SizedBox(
                  height: 20,
                ),
                if (_bookingMessage != null)
                  Text(
                    _bookingMessage!,
                    style: TextStyle(
                        color: _bookingMessage == 'Seat booked successfully'
                            ? Colors.green
                            : Colors.red),
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
