import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'my_app_state.dart';
import 'login_page.dart';

// Main method to initialize Firebase and start the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

// Root of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyAppState(), // Providing MyAppState to the widget tree
      child: MaterialApp(
        title: 'Car Pool',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme:
              ColorScheme.fromSeed(seedColor: Color.fromRGBO(25, 25, 25, 1)),
        ),
        home: AuthWrapper(), // Wrapper to handle authenticated state
      ),
    );
  }
}

// Widget to handle authentication state and direct to the appropriate page
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<MyAppState>(context); // Accessing MyAppState

    // Check if the user is logged in and navigate accordingly
    if (appState.isLoggedIn) {
      return MyHomePage();
    } else {
      return LoginPage();
    }
  }
}
