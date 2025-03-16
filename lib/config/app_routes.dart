import 'package:flutter/material.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/ui/screens/budget_screen.dart';
import 'package:mershed/ui/screens/booking_screen.dart';
import 'package:mershed/ui/screens/forgot_password.dart';
import 'package:mershed/ui/screens/home_screen.dart';
import 'package:mershed/ui/screens/login_screen.dart';
import 'package:mershed/ui/screens/map_screen.dart';
import 'package:mershed/ui/screens/trip_plan_screen.dart';
import 'package:provider/provider.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String trip = '/trip';
  static const String map = '/map';
  static const String booking = '/booking';
  static const String budget = '/budget';
  static const String forgotPassword = '/forgot-password';

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
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }

  static Widget initialRoute(BuildContext context) {
    final authProvider = Provider.of<MershadAuthProvider>(context, listen: true);
    // If user is authenticated, go to home; otherwise, go to login
    return authProvider.user != null ? const HomeScreen() : const LoginScreen();
  }

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    home: (context) => const HomeScreen(),
    trip: (context) => const TripPlanScreen(),
    map: (context) => const MapScreen(),
    booking: (context) => const BookingScreen(),
    budget: (context) => const BudgetScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
  };
}