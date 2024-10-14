import 'package:flutter/material.dart';

class DriverHomepage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> upcomingRides = [
      {'passenger': 'John Doe', 'destination': 'Main Street'},
      {'passenger': 'John Doe', 'destination': '5th Avenue'}
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Driver - Upcming rides'),
      ),
      body: ListView.builder(
        itemCount: upcomingRides.length,
        itemBuilder: (context, index) {
          final ride = upcomingRides[index];
          return ListTile(
            leading: Icon(Icons.person),
            title: Text('Passenger: ${ride['passenger']}'),
            subtitle: Text('Destination ${ride['detination']}'),
            trailing: Icon(Icons.directions_car),
          );
        },
      ),
    );
  }
}
