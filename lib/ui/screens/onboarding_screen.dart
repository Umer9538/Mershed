import 'package:flutter/material.dart';
import 'package:mershed/config/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> onboardingData = [
    {
      'title': 'Welcome to Mershad',
      'description': 'Your AI Travel Companion for Saudi Arabia',
      'icon': Icons.explore,
      'gradient': [
        Color(0xFF1E3A8A),  // Deep blue
        Color(0xFF4A6ACF),  // Lighter blue
      ]
    },
    {
      'title': 'Personalized Travel',
      'description': 'Get tailored recommendations for hotels, activities, and more.',
      'icon': Icons.luggage,
      'gradient': [
        Color(0xFF4A6ACF),  // Lighter blue
        Color(0xFF6FDFDF),  // Turquoise
      ]
    },
    {
      'title': 'Explore with Ease',
      'description': 'Navigate Saudi Arabia seamlessly with real-time guidance.',
      'icon': Icons.location_on,
      'gradient': [
        Color(0xFF6FDFDF),  // Turquoise
        Color(0xFF9DECB4),  // Soft green
      ]
    },
    {
      'title': 'Hassle-Free Car Rentals',
      'description': 'Get step-by-step guidance for car rentals with Absher & Nafath.',
      'icon': Icons.directions_car,
      'gradient': [
        Color(0xFF9DECB4),  // Soft green
        Color(0xFFF5D5A2),  // Desert sand
      ]
    },
    {
      'title': 'Travel Respectfully',
      'description': 'Learn cultural tips and local laws for a respectful journey.',
      'icon': Icons.info,
      'gradient': [
        Color(0xFFF5D5A2),  // Desert sand
        Color(0xFFFFB74D),  // Light orange
      ]
    },
    {
      'title': 'Plan Your Budget',
      'description': 'Set your budget and get cost-effective travel suggestions.',
      'icon': Icons.account_balance_wallet,
      'gradient': [
        Color(0xFFFFB74D),  // Light orange
        Color(0xFFFF7043),  // Deep orange
      ]
    },
    {
      'title': 'Book with Ease',
      'description': 'Reserve hotels, activities, and restaurants in just a few taps.',
      'icon': Icons.hotel,
      'gradient': [
        Color(0xFFFF7043),  // Deep orange
        Color(0xFFF44336),  // Red
      ]
    },
    {
      'title': 'Stay Safe',
      'description': 'Access emergency contacts and safety alerts instantly.',
      'icon': Icons.emergency,
      'gradient': [
        Color(0xFFF44336),  // Red
        Color(0xFF1E3A8A),  // Deep blue
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Onboarding Pages
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: onboardingData.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: onboardingData[index]['gradient'],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon
                      Icon(
                        onboardingData[index]['icon'],
                        size: 120,
                        color: const Color(0xFFFFD700), // Gold accent
                      ),
                      const SizedBox(height: 40),

                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          onboardingData[index]['title'],
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          onboardingData[index]['description'],
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Skip Button
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Page Indicator and Navigation
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Page Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    onboardingData.length,
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: _currentPage == index ? 16 : 10,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFFFFD700)  // Active dot color
                            : Colors.white54,  // Inactive dot color
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Next/Get Started Button
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == onboardingData.length - 1) {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutQuart,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700), // Gold
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    _currentPage == onboardingData.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}