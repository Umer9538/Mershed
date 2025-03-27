import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mershed/config/app_routes.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/core/providers/recommendation_provider.dart';
import 'package:mershed/core/providers/trip_provider.dart';
import 'package:mershed/core/theme_provider.dart';
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
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ScreenUtilInit( // Wrap MaterialApp with ScreenUtilInit
                designSize: const Size(360, 640), // Design size based on the screenshot
                minTextAdapt: true,
                splitScreenMode: true,
                builder: (context, child) {
                  return MaterialApp(
                    debugShowCheckedModeBanner: false, // Add this to remove debug banner
                    title: 'Mershed',
                    theme: themeProvider.themeData,
                    initialRoute: AppRoutes.splash,
                    routes: AppRoutes.routes,
                    onGenerateRoute: AppRoutes.generateRoute,
                  );
                },
              );
            },
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
import 'package:mershed/core/theme_provider.dart';
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
            ChangeNotifierProvider(create: (_) => ThemeProvider()), // Add ThemeProvider
          ],
          child: Consumer<ThemeProvider>( // Use Consumer to listen to theme changes
            builder: (context, themeProvider, child) {
              return MaterialApp(
                title: 'Mershed',
                theme: themeProvider.themeData, // Dynamic theme from ThemeProvider
                home: Builder(
                  builder: (context) {
                    print('Evaluating initial route...');
                    return AppRoutes.initialRoute(context);
                  },
                ),
                routes: AppRoutes.routes,
                onGenerateRoute: AppRoutes.generateRoute,
              );
            },
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


*/
