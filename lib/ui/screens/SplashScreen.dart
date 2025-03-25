import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _TravelSplashScreenState createState() => _TravelSplashScreenState();
}

class _TravelSplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Increased animation duration to 3 seconds
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Scale animation - makes the logo grow and then slightly shrink
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    // Fade animation - subtle fade in effect
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4CB8C4), // Soft teal
              Color(0xFF3CD3AD), // Mint green
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SvgPicture.string(
                    '''
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
                      <defs>
                        <linearGradient id="logoGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                          <stop offset="0%" style="stop-color:#FFFFFF;stop-opacity:1" />
                          <stop offset="100%" style="stop-color:#F0F0F0;stop-opacity:0.8" />
                        </linearGradient>
                      </defs>
                      <path d="M100 20 L140 80 Q160 100, 140 120 L100 180 L60 120 Q40 100, 60 80 Z" 
                            fill="url(#logoGradient)" 
                            stroke="#FFFFFF" 
                            stroke-width="3"/>
                      <circle cx="100" cy="100" r="10" fill="#FFFFFF"/>
                    </svg>
                    ''',
                    width: 180,
                    height: 180,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Animated text
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Wanderlust',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}