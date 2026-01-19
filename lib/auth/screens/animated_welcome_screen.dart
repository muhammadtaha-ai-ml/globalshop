import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'login_screen.dart';
import 'signup_screen.dart';

class AnimatedWelcomeScreen extends StatefulWidget {
  const AnimatedWelcomeScreen({super.key});

  @override
  State<AnimatedWelcomeScreen> createState() => _AnimatedWelcomeScreenState();
}

class _AnimatedWelcomeScreenState extends State<AnimatedWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4A90E2),
              Color(0xFF5B9BD5),
              Color(0xFF70C1E8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Illustration Section with White Card
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Stack(
                            children: [
                              // Background decorative circles
                              Positioned(
                                top: -50,
                                right: -50,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                                  ),
                                ),
                              ),
                              
                              // Main illustration placeholder
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Image placeholder with instructions
                                    Container(
                                      width: 280,
                                      height: 240,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F4F8),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/images/welcome_illustration.png',
                                            width: 260,
                                            height: 220,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              // Fallback illustration using icons
                                              return _buildFallbackIllustration();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 30),
                                    
                                    // Title
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 24),
                                      child: Text(
                                        'Discover Your\nDream Shop here',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A365D),
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Subtitle
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 32),
                                      child: Text(
                                        'Explore all the existing smart devices\nbased on your interest and preferences',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Decorative magnifying glass (bottom left)
                              Positioned(
                                bottom: -20,
                                left: -20,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                      color: const Color(0xFF4A90E2).withOpacity(0.3),
                                      width: 8,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.search_rounded,
                                    size: 40,
                                    color: const Color(0xFF4A90E2).withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Section - Buttons
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Buttons Row
                          Row(
                            children: [
                              // Login Button
                              Expanded(
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF4A90E2),
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      "Login",
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Register Button
                              Expanded(
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const SignupScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      "Register",
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fallback illustration if image is not found
  Widget _buildFallbackIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background circles
        Positioned(
          top: 30,
          right: 40,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4A90E2).withOpacity(0.1),
            ),
          ),
        ),
        
        // IoT Cloud
        Positioned(
          top: 20,
          right: 50,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'IoT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        // Person with laptop
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Person icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 60,
                color: Color(0xFF4A90E2),
              ),
            ),
            const SizedBox(height: 10),
            
            // Laptop
            Container(
              width: 80,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF1A365D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.laptop_mac_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Devices
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDeviceIcon(Icons.smartphone_rounded),
                const SizedBox(width: 15),
                _buildDeviceIcon(Icons.watch_rounded),
                const SizedBox(width: 15),
                _buildDeviceIcon(Icons.lightbulb_outline_rounded),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeviceIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 24,
        color: const Color(0xFF4A90E2),
      ),
    );
  }
}