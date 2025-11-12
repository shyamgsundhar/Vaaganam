import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:vaaganam/providers/auth_provider.dart';
import 'package:vaaganam/screens/driver.dart';
import 'package:vaaganam/screens/dispatcher.dart';
import 'package:vaaganam/screens/trip_details.dart';
import 'package:vaaganam/screens/trip_in_progress.dart';
import 'package:vaaganam/screens/trip_summary.dart';
import 'package:vaaganam/screens/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Firebase initialization failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'VaaGanam',
        theme: ThemeData(
          // Primary look: Orange (buttons/accents) and Black (text/appbar)
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            primary: Colors.orange,
            onPrimary: Colors.black,
            secondary: Colors.black,
            onSecondary: Colors.white,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            titleTextStyle: TextStyle(
              color: Colors.orange,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            iconTheme: IconThemeData(color: Colors.orange),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            labelStyle: const TextStyle(color: Colors.black),
            hintStyle: const TextStyle(color: Colors.black54),
            prefixIconColor: Colors.black,
            suffixIconColor: Colors.black,
            filled: true,
            fillColor: Colors.white,
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black54),
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.orange, width: 2.0),
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          ),
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Colors.orange,
            selectionColor: Colors.orangeAccent,
            selectionHandleColor: Colors.orange,
          ),
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            switch (authProvider.status) {
              case AuthStatus.uninitialized:
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              case AuthStatus.authenticated:
                if (authProvider.isDriver) {
                  return const DriverPage();
                } else if (authProvider.isDispatcher) {
                  return const DispatcherPage();
                }
                return LoginPage();
              case AuthStatus.unauthenticated:
              case AuthStatus.authenticating:
                return LoginPage();
            }
          },
        ),
        routes: {
          '/login': (context) => LoginPage(),
          '/driver': (context) => const DriverPage(),
          '/dispatcher': (context) => const DispatcherPage(),
          '/trip_details': (context) => const TripDetailsPage(),
          '/trip_in_progress': (context) => const TripInProgressPage(),
          '/trip_summary': (context) => const TripSummaryPage(),
        },
      ),
    );
  }
}
