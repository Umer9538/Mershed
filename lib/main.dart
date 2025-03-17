import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mershed/config/app_routes.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/core/providers/recommendation_provider.dart';
import 'package:mershed/core/providers/trip_provider.dart';
import 'package:mershed/firebase_options.dart';
import 'package:mershed/ui/themes/app_theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Initializing Firebase...');
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building MyApp...');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          print('Creating MershadAuthProvider...');
          return MershadAuthProvider();
        }),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
      ],
      child: MaterialApp(
        title: 'Mershad',
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            print('Evaluating initial route...');
            return AppRoutes.initialRoute(context);
          },
        ),
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}











/*
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mershed/config/app_routes.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/core/providers/recommendation_provider.dart';
import 'package:mershed/core/providers/trip_provider.dart';
import 'package:mershed/firebase_options.dart';
import 'package:mershed/ui/themes/app_theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Initializing Firebase...');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building MyApp...');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          print('Creating MershadAuthProvider...');
          return MershadAuthProvider();
        }),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
      ],
      child: MaterialApp(
        title: 'Mershad',
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            print('Evaluating initial route...');
            return AppRoutes.initialRoute(context);
          },
        ),
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}*/
