import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:car_pool/providers/my_app_state.dart';

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<MyAppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Car Pool'),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${appState.userEmail}!'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle your ride booking here
              },
              child: Text('Book a ride'),
            ),
          ],
        ),
      ),
    );
  }
}
