import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/ui/screens/budget_screen.dart';
import 'package:mershed/ui/screens/booking_screen.dart';
import 'package:mershed/ui/screens/CulturalInsightsScreen.dart';
import 'package:mershed/ui/screens/map_screen.dart';
import 'package:mershed/ui/screens/trip_plan_screen.dart';
import 'package:provider/provider.dart';
import 'package:mershed/config/app_routes.dart';
import 'navigation_transport_screen.dart';
import 'chatbot_screen.dart';
import 'settings_screen.dart'; // New import for SettingsScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final primaryColor = Color(0xFFB94A2F);
    final accentColor = Color(0xFF3C896D);
    final backgroundColor = Color(0xFFF7EFE4);
    final authProvider = Provider.of<MershadAuthProvider>(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          _buildTopBackground(size, primaryColor),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, authProvider),
                SizedBox(height: 20),
                _buildFeaturedDestination(size),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Explore Services',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
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
                          enabled: true,
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
                          enabled: true,
                        ),
                        _buildMenuCard(
                          context,
                          'Find Hotels',
                          Icons.hotel,
                          Colors.purple.shade700,
                          authProvider.isAuthenticated
                              ? () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const BookingScreen()),
                          )
                              : () => _showAuthRequiredDialog(context),
                          enabled: authProvider.isAuthenticated,
                        ),
                        _buildMenuCard(
                          context,
                          'Budget',
                          Icons.account_balance_wallet,
                          Colors.green.shade700,
                          authProvider.isAuthenticated
                              ? () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const BudgetScreen()),
                          )
                              : () => _showAuthRequiredDialog(context),
                          enabled: authProvider.isAuthenticated,
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
                          enabled: true,
                        ),
                        _buildMenuCard(
                          context,
                          'Chatbot',
                          Icons.chat,
                          Colors.teal.shade700,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChatbotScreen()),
                          ),
                          enabled: true,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
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

  Widget _buildHeader(BuildContext context, MershadAuthProvider authProvider) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
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
              StreamBuilder<DocumentSnapshot>(
                stream: userId != null
                    ? FirebaseFirestore.instance.collection('users').doc(userId).snapshots()
                    : null,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                    return Text(
                      authProvider.isGuest ? 'Guest' : 'Explorer!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    );
                  }
                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  final userName = userData['name'] ?? 'Explorer!';
                  return Text(
                    authProvider.isGuest ? 'Guest' : userName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  );
                },
              ),
            ],
          ),
          Row(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: userId != null
                    ? FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('notifications')
                    .where('read', isEqualTo: false)
                    .snapshots()
                    : null,
                builder: (context, snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData) {
                    unreadCount = snapshot.data!.docs.length;
                  }
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.notifications_none, color: Colors.white),
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.notifications);
                          },
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              SizedBox(width: 10),
              StreamBuilder<DocumentSnapshot>(
                stream: userId != null
                    ? FirebaseFirestore.instance.collection('users').doc(userId).snapshots()
                    : null,
                builder: (context, snapshot) {
                  String profileImage = 'assets/images/profile_placeholder.webp';
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final userData = snapshot.data!.data() as Map<String, dynamic>;
                    profileImage = userData['profileImage'] ?? profileImage;
                  }
                  return GestureDetector(
                    onTap: () => _showProfileOptions(context),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white24, // Optional: add background color
                      child: Icon(
                        Icons.person, // Use person icon instead of image
                        color: Colors.white, // Adjust color as needed
                        size: 28, // Adjust size as needed
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedDestination(Size size) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('featured_destinations')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 24),
            height: size.height * 0.2,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final fallbackName = 'Discover Saudi Arabia';
        final fallbackLocation = 'Various Locations';
        final fallbackRating = '4.5';
        final fallbackImageUrl = 'assets/images/generic_destination.jpg';

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 24),
            height: size.height * 0.2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: AssetImage(fallbackImageUrl),
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
                        fallbackName,
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
                            fallbackRating,
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
                            fallbackLocation,
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
                Positioned(
                  top: 15,
                  right: 15,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.search);
                    },
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
                ),
              ],
            ),
          );
        }

        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Mystical Trails Mushroom Forest';
        final location = data['location'] ?? 'Enchanted Valley';
        final rating = data['rating']?.toString() ?? '4.8';
        final imageUrl = data['imageUrl'] ?? 'assets/images/featured_destination.jpeg';

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 24),
          height: size.height * 0.2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
              onError: (_, __) => AssetImage('assets/images/featured_destination.jpeg'),
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
                      name,
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
                          rating,
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
                          location,
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
              Positioned(
                top: 15,
                right: 15,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.destinationDetail,
                      arguments: doc.id,
                    );
                  },
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap,
      {bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(enabled ? 0.2 : 0.1),
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
                color: color.withOpacity(enabled ? 0.1 : 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: enabled ? color : Colors.grey,
                size: 32,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.brown.shade800 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(Color primaryColor) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
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
          _buildNavItem(Icons.home, 'Home', primaryColor, 0),
          _buildNavItem(Icons.search, 'Search', primaryColor, 1),
          StreamBuilder<QuerySnapshot>(
            stream: userId != null
                ? FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('saved_destinations')
                .snapshots()
                : null,
            builder: (context, snapshot) {
              int savedCount = 0;
              if (snapshot.hasData) {
                savedCount = snapshot.data!.docs.length;
              }
              return Stack(
                children: [
                  _buildNavItem(Icons.favorite_border, 'Saved', primaryColor, 2),
                  if (savedCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$savedCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          _buildNavItem(Icons.person_outline, 'Profile', primaryColor, 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, Color color, int index) {
    bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        switch (index) {
          case 0:
            break;
          case 1:
            Navigator.pushNamed(context, AppRoutes.search);
            break;
          case 2:
            Navigator.pushNamed(context, AppRoutes.saved);
            break;
          case 3:
            Navigator.pushNamed(context, AppRoutes.profile);
            break;
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? color : Colors.grey,
            size: 28,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? color : Colors.grey,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileOptions(BuildContext context) {
    final authProvider = Provider.of<MershadAuthProvider>(context, listen: false);
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
              'Settings',
                  () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ),
            ),
            Divider(),
            _buildProfileOption(
              Icons.logout,
              authProvider.isGuest ? 'Exit Guest Mode' : 'Sign Out',
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
    final authProvider = Provider.of<MershadAuthProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(authProvider.isGuest ? 'Exit Guest Mode' : 'Sign Out'),
        content: Text(authProvider.isGuest
            ? 'Are you sure you want to exit guest mode?'
            : 'Are you sure you want to sign out?'),
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
            child: Text(
              authProvider.isGuest ? 'Exit' : 'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAuthRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Authentication Required'),
        content: Text('Please sign in to access this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.login);
            },
            child: Text('Sign In', style: TextStyle(color: Color(0xFFB94A2F))),
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