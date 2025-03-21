import 'package:flutter/material.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/ui/screens/budget_screen.dart';
import 'package:mershed/ui/screens/booking_screen.dart';
import 'package:mershed/ui/screens/CulturalInsightsScreen.dart'; // Added
import 'package:mershed/ui/screens/forgot_password.dart';
import 'package:mershed/ui/screens/home_screen.dart';
import 'package:mershed/ui/screens/login_screen.dart';
import 'package:mershed/ui/screens/map_screen.dart';
import 'package:mershed/ui/screens/signup_screen.dart';
import 'package:mershed/ui/screens/trip_plan_screen.dart';
import 'package:mershed/ui/screens/navigation_transport_screen.dart';
import 'package:mershed/ui/screens/preferences_screen.dart';
import 'package:mershed/ui/screens/profile_screen.dart';
import 'package:provider/provider.dart';

import '../ui/screens/CulturalInsightsScreen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String trip = '/trip';
  static const String map = '/map';
  static const String booking = '/booking';
  static const String budget = '/budget';
  static const String forgotPassword = '/forgot-password';
  static const String signup = '/signup';
  static const String preferences = '/preferences';
  static const String profile = '/profile';
  static const String navigationTransport = '/navigation-transport';
  static const String culturalInsights = '/cultural-insights'; // Added

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case trip:
        return MaterialPageRoute(builder: (_) => const TripPlanScreen());
      case map:
        return MaterialPageRoute(builder: (_) => const MapScreen());
      case booking:
        return MaterialPageRoute(builder: (_) => const BookingScreen());
      case budget:
        return MaterialPageRoute(builder: (_) => const BudgetScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case preferences:
        return MaterialPageRoute(builder: (_) => const PreferencesScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case navigationTransport:
        return MaterialPageRoute(builder: (_) => const NavigationTransportScreen());
      case culturalInsights: // Added
        return MaterialPageRoute(builder: (_) => const CulturalInsightsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }

  static Widget initialRoute(BuildContext context) {
    final authProvider = Provider.of<MershadAuthProvider>(context, listen: true);
    return authProvider.isAuthenticated || authProvider.isGuest ? const HomeScreen() : const LoginScreen();
  }

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    home: (context) => const HomeScreen(),
    trip: (context) => const TripPlanScreen(),
    map: (context) => const MapScreen(),
    booking: (context) => const BookingScreen(),
    budget: (context) => const BudgetScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    signup: (context) => const SignupScreen(),
    preferences: (context) => const PreferencesScreen(),
    profile: (context) => const ProfileScreen(),
    navigationTransport: (context) => const NavigationTransportScreen(),
    culturalInsights: (context) => const CulturalInsightsScreen(), // Added
  };
}