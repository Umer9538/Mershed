import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/ui/screens/budget_screen.dart';
import 'package:mershed/ui/screens/booking_screen.dart';
import 'package:mershed/ui/screens/CulturalInsightsScreen.dart';
import 'package:mershed/ui/screens/map_screen.dart';
import 'package:mershed/ui/screens/trip_plan_screen.dart';
import 'package:provider/provider.dart';
import 'package:mershed/config/app_routes.dart';
import 'navigation_transport_screen.dart';
import 'chatbot_screen.dart'; // Added import for ChatbotScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // User's profile picture could be fetched from provider in real app
  final String _profileImage = 'assets/images/profile_placeholder.webp';

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final primaryColor = Color(0xFFB94A2F); // Using the mushroom app primary color
    final accentColor = Color(0xFF3C896D); // Forest green - nature related
    final backgroundColor = Color(0xFFF7EFE4); // Light background

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Top curved background
          _buildTopBackground(size, primaryColor),

          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),

                SizedBox(height: 20),

                // Featured destination card
                _buildFeaturedDestination(size),

                SizedBox(height: 20),

                // Category Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Explore Services',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade800,
                        ),
                      ),
                      Text(
                        'View All',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Main menu grid
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      children: [
                        _buildMenuCard(
                          context,
                          'Plan a Trip',
                          Icons.map,
                          Colors.blue.shade700,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TripPlanScreen()),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          'Navigation & Transport',
                          Icons.directions,
                          Colors.orange.shade700,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NavigationTransportScreen()),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          'Find Hotels',
                          Icons.hotel,
                          Colors.purple.shade700,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const BookingScreen()),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          'Budget',
                          Icons.account_balance_wallet,
                          Colors.green.shade700,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const BudgetScreen()),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          'Cultural Insights',
                          Icons.info,
                          Colors.red.shade700,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CulturalInsightsScreen()),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          'Chatbot', // New card for Chatbot
                          Icons.chat,
                          Colors.teal.shade700, // Teal color for the chatbot card
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChatbotScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 10),

                // Bottom navigation
                _buildBottomNavigation(primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBackground(Size size, Color primaryColor) {
    return Container(
      height: size.height * 0.3,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Explorer!', // Could be actual username
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.notifications_none, color: Colors.white),
                  onPressed: () {},
                ),
              ),
              SizedBox(width: 10),
              GestureDetector(
                onTap: () => _showProfileOptions(context),
                child: CircleAvatar(
                  radius: 22,
                  backgroundImage: AssetImage(_profileImage),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedDestination(Size size) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      height: size.height * 0.2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage('assets/images/featured_destination.jpeg'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Featured Destination',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Mystical Trails Mushroom Forest',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '4.8',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(
                      Icons.location_on,
                      color: Colors.white70,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Enchanted Valley',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Explore button
          Positioned(
            top: 15,
            right: 15,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFFB94A2F).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Explore',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              offset: Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.brown.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(Color primaryColor) {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', primaryColor, true),
          _buildNavItem(Icons.search, 'Search', Colors.grey, false),
          _buildNavItem(Icons.favorite_border, 'Saved', Colors.grey, false),
          _buildNavItem(Icons.person_outline, 'Profile', Colors.grey, false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, Color color, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _showProfileOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Profile Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade800,
              ),
            ),
            SizedBox(height: 20),
            _buildProfileOption(
              Icons.person,
              'View Profile',
                  () => Navigator.pushNamed(context, AppRoutes.profile),
            ),
            Divider(),
            _buildProfileOption(
              Icons.settings,
              'Preferences',
                  () => Navigator.pushNamed(context, AppRoutes.preferences),
            ),
            Divider(),
            _buildProfileOption(
              Icons.settings,
              'Settings',
                  () => Navigator.pop(context),
            ),
            Divider(),
            _buildProfileOption(
              Icons.logout,
              'Sign Out',
                  () {
                Navigator.pop(context);
                _confirmSignOut(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<MershadAuthProvider>().signOut();
                Navigator.pop(context); // Close the dialog
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error signing out: $e')),
                );
              }
            },
            child: Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Color(0xFFB94A2F)),
            SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.brown.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}