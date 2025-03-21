import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mershed/config/app_routes.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/core/providers/recommendation_provider.dart';
import 'package:mershed/core/providers/trip_provider.dart';
import 'package:mershed/firebase_options.dart';
import 'package:mershed/ui/themes/app_theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Initializing app...',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Failed to initialize app', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Error: ${snapshot.error.toString()}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => (context as Element).markNeedsBuild(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

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
            title: 'Mershed',
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
      },
    );
  }

  Future<void> _initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables
    print('Loading environment variables...');
    try {
      await dotenv.load(fileName: ".env");
      print('Environment variables loaded successfully');
    } catch (e) {
      print('Failed to load environment variables: $e');
      throw Exception('Failed to load environment variables: $e');
    }

    // Initialize Firebase
    print('Initializing Firebase...');
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization failed: $e');
      throw Exception('Firebase initialization failed: $e');
    }
  }
}


/*
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mershed/config/app_routes.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/core/providers/recommendation_provider.dart';
import 'package:mershed/core/providers/trip_provider.dart';
import 'package:mershed/firebase_options.dart';
import 'package:mershed/ui/themes/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiConfig {
  static const _storage = FlutterSecureStorage();
  static const _apiKeyKey = 'hotelbeds_api_key';
  static const _secretKey = 'hotelbeds_secret';

  static Future<void> saveCredentials(String apiKey, String secret) async {
    await _storage.write(key: _apiKeyKey, value: apiKey);
    await _storage.write(key: _secretKey, value: secret);
    final savedApiKey = await _storage.read(key: _apiKeyKey);
    final savedSecret = await _storage.read(key: _secretKey);
    print('Saved API Key: $savedApiKey, Saved Secret: $savedSecret');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize secure storage with API credentials
  await ApiConfig.saveCredentials('6d28cfa54bc8095c2356f91ff643fa3', '1c68a0d319');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Initializing app...',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to initialize app',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error: ${snapshot.error.toString()}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        (context as Element).markNeedsBuild();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

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
            title: 'Mershed',
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
      },
    );
  }

  Future<void> _initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables
    print('Loading environment variables...');
    try {
      await dotenv.load(fileName: ".env");
      print('Environment variables loaded successfully');
    } catch (e) {
      print('Failed to load environment variables: $e');
      throw Exception('Failed to load environment variables: $e');
    }

    // Initialize Firebase
    print('Initializing Firebase...');
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization failed: $e');
      throw Exception('Firebase initialization failed: $e');
    }
  }
}*/
