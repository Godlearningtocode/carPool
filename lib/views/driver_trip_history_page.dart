import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:car_pool/services/trip_service.dart';
import 'package:car_pool/utils/date_time_util.dart';
import 'package:car_pool/providers/my_app_state.dart';
import 'package:car_pool/views/trip_map_page.dart'; // Assuming this exists

class DriverTripHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<MyAppState>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Trip History'),
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: TripService.fetchTripHistory(appState.idToken!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            final groupedTrips = snapshot.data!;
            return ListView(
                children: groupedTrips.entries.map(
              (entry) {
                final driverName = entry.key;
                final trips = entry.value;

                return ExpansionTile(
                  title: Text(
                    driverName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  children: trips.map((trip) {
                    return ListTile(
                      title: Text(
                        'Trip: ${DateTimeUtil.formatDateTime(trip['startTime'])} - ${DateTimeUtil.formatDateTime(trip['endTime'])}',
                      ),
                      trailing: Icon(Icons.map),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TripMapPage(tripData: trip['tripData']),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ).toList());
          }
        },
      ),
    );
  }
}
