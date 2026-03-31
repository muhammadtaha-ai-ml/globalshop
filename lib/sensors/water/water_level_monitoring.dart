import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math' as math;

class WaterLevelMonitoringScreen extends StatefulWidget {
  final String deviceId;

  const WaterLevelMonitoringScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<WaterLevelMonitoringScreen> createState() =>
      _WaterLevelMonitoringScreenState();
}

class _WaterLevelMonitoringScreenState
    extends State<WaterLevelMonitoringScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _bubbleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Wave animation controller
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Bubble animation
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Fade in animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    // Scale animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );
    _scaleController.forward();

    // Glow animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  // Calculate percentage based on 7 levels (1-7)
  double _calculatePercentage(int waterLevel) {
    if (waterLevel < 1) return 0;
    if (waterLevel > 7) return 100;
    return (waterLevel / 7) * 100;
  }

  String _getLevelDescription(int waterLevel) {
    switch (waterLevel) {
      case 1:
        return "VERY LOW";
      case 2:
        return "LOW";
      case 3:
        return "MEDIUM LOW";
      case 4:
        return "MEDIUM";
      case 5:
        return "MEDIUM HIGH";
      case 6:
        return "HIGH";
      case 7:
        return "VERY HIGH";
      default:
        return "Unknown";
    }
  }

  Color _getLevelColor(int waterLevel) {
    if (waterLevel <= 2) return const Color(0xFFFF6B9D); // Pink-Red
    if (waterLevel <= 4) return const Color(0xFFFFB74D); // Warm Orange
    return const Color(0xFF4FC3F7); // Sky Blue
  }

  IconData _getLevelIcon(int waterLevel) {
    if (waterLevel <= 2) return Icons.water_drop_outlined;
    if (waterLevel <= 4) return Icons.water_drop;
    return Icons.water_drop_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final logsRef = FirebaseDatabase.instance
        .ref('devices')
        .child(widget.deviceId)
        .child('logs')
        .limitToLast(1);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F9FF), // Very light blue
              Color(0xFFFAFDFF), // Almost white blue
              Color(0xFFFFFFFF), // Pure white
              Color(0xFFF5FAFF), // Light blue tint
            ],
          ),
        ),
        child: StreamBuilder<DatabaseEvent>(
          stream: logsRef.onValue,
          builder: (context, snapshot) {
            // Loading state
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return _buildLoadingState();
            }

            final Map logs = Map<String, dynamic>.from(
                snapshot.data!.snapshot.value as Map);
            final latestLog = logs.values.first;
            final int waterLevel = latestLog['waterLevel'] ?? 0;
            final String time = latestLog['time'] ?? "--";
            final double percentage = _calculatePercentage(waterLevel);
            final String levelDescription = _getLevelDescription(waterLevel);
            final Color levelColor = _getLevelColor(waterLevel);
            final IconData levelIcon = _getLevelIcon(waterLevel);

            return SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Modern App Bar - STANDARDIZED SIZE (same as device_dashboard_screen.dart)
                    _buildModernAppBar(context),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: 6),

                            // Main Water Tank Display - REDUCED SIZE
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: _buildWaterTankCard(
                                percentage,
                                levelColor,
                                waterLevel,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Single Status Card - COMPACT
                            _buildStatusCard(
                              levelDescription,
                              levelColor,
                              levelIcon,
                            ),

                            const SizedBox(height: 10),

                            // Date & Time Row - COMPACT & VISIBLE
                            _buildDateTimeRow(time),

                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button with gradient - COMPACT
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF42A5F5).withOpacity(0.1),
                  const Color(0xFF1E88E5).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF1976D2),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),

          // Water Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4FC3F7).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.waves_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Title - COMPACT
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Water Monitor',
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Live tracking system',
                  style: TextStyle(
                    color: Color(0xFF64B5F6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Status indicator - COMPACT
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50)
                          .withOpacity(0.3 + _glowAnimation.value * 0.2),
                      blurRadius: 6,
                      spreadRadius: _glowAnimation.value * 1.5,
                    ),
                  ],
                ),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTankCard(
    double percentage,
    Color levelColor,
    int waterLevel,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFFAFDFF),
          ],
        ),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: levelColor.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.15),
            blurRadius: 35,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 10),
            ],
          ),
          const SizedBox(height: 16),

          // Animated Water Tank - REDUCED HEIGHT
          SizedBox(
            height: 340,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 250,
                      height: 340,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: levelColor.withOpacity(0.15 + _glowAnimation.value * 0.1),
                            blurRadius: 25 + _glowAnimation.value * 8,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Water Tank Visual with bubbles - REDUCED SIZE
                AnimatedBuilder(
                  animation: Listenable.merge([_waveController, _bubbleController]),
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(200, 280),
                      painter: EnhancedWaterTankPainter(
                        percentage: percentage,
                        color: levelColor,
                        wavePhase: _waveController.value,
                        bubblePhase: _bubbleController.value,
                      ),
                    );
                  },
                ),

                // Percentage Display only (no status inside)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated icon with glow - COMPACT
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: levelColor.withOpacity(0.3 + _glowAnimation.value * 0.2),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.water_drop_rounded,
                            size: 50,
                            color: levelColor,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Percentage with shadow - SLIGHTLY SMALLER
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: percentage),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Stack(
                          children: [
                            // Shadow
                            Text(
                              '${value.toInt()}%',
                              style: TextStyle(
                                fontSize: 75,
                                fontWeight: FontWeight.w900,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 7
                                  ..color = levelColor.withOpacity(0.1),
                                letterSpacing: -3,
                                height: 1,
                              ),
                            ),
                            // Main text
                            Text(
                              '${value.toInt()}%',
                              style: TextStyle(
                                fontSize: 70,
                                fontWeight: FontWeight.w900,
                                color: levelColor,
                                letterSpacing: -3,
                                height: 1,
                                shadows: [
                                  Shadow(
                                    color: levelColor.withOpacity(0.3),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Single Status Card (replacing 3 cards) - COMPACT
  Widget _buildStatusCard(
    String levelDescription,
    Color levelColor,
    IconData levelIcon,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            levelColor.withOpacity(0.15),
            levelColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: levelColor.withOpacity(0.3),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon with gradient background - COMPACT
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [levelColor, levelColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: levelColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              levelIcon,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),

          // Status Info - COMPACT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Water Status',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  levelDescription,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: levelColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Decorative element - COMPACT
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: levelColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: levelColor,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  // Date & Time Row - COMPACT
  Widget _buildDateTimeRow(String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoCard(
              icon: Icons.calendar_today_rounded,
              label: 'Date',
              value: _formatDate(time),
              gradient: const [Color(0xFFFA709A), Color(0xFFFEE140)],
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildInfoCard(
              icon: Icons.access_time_rounded,
              label: 'Time',
              value: _formatTime(time),
              gradient: const [Color(0xFF30CFD0), Color(0xFF330867)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF4FC3F7).withOpacity(0.3),
                      const Color(0xFF4FC3F7).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
              // Main container
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4FC3F7).withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4FC3F7)),
                  strokeWidth: 5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            'Loading Water Data...',
            style: TextStyle(
              color: Color(0xFF4FC3F7),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String time) {
    try {
      if (time == "--") return "-- --- ----";
      final parts = time.split(' ')[0].split('-');
      if (parts.length == 3) {
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return "${parts[2]} ${months[int.parse(parts[1]) - 1]} ${parts[0]}";
      }
      return time;
    } catch (e) {
      return time;
    }
  }

  String _formatTime(String time) {
    try {
      if (time == "--") return "--:--";
      final timePart = time.split(' ')[1];
      final parts = timePart.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        hour = hour % 12;
        if (hour == 0) hour = 12;
        return "$hour:$minute $period";
      }
      return time;
    } catch (e) {
      return time;
    }
  }
}

// Enhanced Water Tank Painter with Wave Effect and Bubbles
class EnhancedWaterTankPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double wavePhase;
  final double bubblePhase;

  EnhancedWaterTankPainter({
    required this.percentage,
    required this.color,
    required this.wavePhase,
    required this.bubblePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Tank outline with gradient border
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.4),
          color.withOpacity(0.2),
          color.withOpacity(0.4),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final tankRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.15,
        size.height * 0.03,
        size.width * 0.7,
        size.height * 0.94,
      ),
      const Radius.circular(40),
    );
    canvas.drawRRect(tankRect, outlinePaint);

    // Draw background pattern
    final bgPaint = Paint()
      ..color = color.withOpacity(0.03)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(tankRect, bgPaint);

    // Water fill with enhanced wave effect
    if (percentage > 0) {
      final fillHeight = (size.height * 0.94) * (percentage / 100);
      final waterTop = size.height * 0.97 - fillHeight;

      // Create enhanced wave path
      final wavePath = Path();
      wavePath.moveTo(size.width * 0.15, size.height * 0.97);
      wavePath.lineTo(size.width * 0.15, waterTop + 12);

      // Draw double wave for more realistic effect
      for (double i = 0; i <= size.width * 0.7; i++) {
        final x = size.width * 0.15 + i;
        final wave1 = math.sin((i / 18) + (wavePhase * 2 * math.pi)) * 10;
        final wave2 = math.sin((i / 25) - (wavePhase * 2 * math.pi)) * 6;
        final y = waterTop + 12 + wave1 + wave2;
        wavePath.lineTo(x, y);
      }

      wavePath.lineTo(size.width * 0.85, size.height * 0.97);
      wavePath.close();

      // Clip to tank shape
      canvas.save();
      canvas.clipRRect(tankRect);

      // Fill with enhanced gradient
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.5),
            color.withOpacity(0.7),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, waterTop, size.width, fillHeight));

      canvas.drawPath(wavePath, fillPaint);

      // Draw bubbles
      if (percentage > 15) {
        _drawBubbles(canvas, size, waterTop, fillHeight);
      }

      // Add enhanced shimmer effect
      final shimmerPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.4),
            Colors.transparent,
            Colors.white.withOpacity(0.3),
            Colors.transparent,
            Colors.white.withOpacity(0.2),
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(tankRect.outerRect);

      canvas.drawRect(
        Rect.fromLTWH(
          size.width * 0.15,
          waterTop,
          size.width * 0.7,
          fillHeight,
        ),
        shimmerPaint,
      );

      canvas.restore();
    }

    // Add inner shadow effect
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.03),
        ],
      ).createShader(tankRect.outerRect);

    canvas.save();
    canvas.clipRRect(tankRect);
    canvas.drawRect(tankRect.outerRect, shadowPaint);
    canvas.restore();
  }

  void _drawBubbles(Canvas canvas, Size size, double waterTop, double fillHeight) {
    final bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Draw multiple animated bubbles
    final bubbles = [
      {'x': 0.25, 'y': 0.7, 'size': 6.0, 'speed': 1.0},
      {'x': 0.45, 'y': 0.5, 'size': 4.0, 'speed': 1.5},
      {'x': 0.65, 'y': 0.8, 'size': 5.0, 'speed': 0.8},
      {'x': 0.35, 'y': 0.3, 'size': 3.5, 'speed': 1.2},
      {'x': 0.55, 'y': 0.6, 'size': 4.5, 'speed': 1.1},
    ];

    for (var bubble in bubbles) {
      final x = size.width * 0.15 + (size.width * 0.7 * bubble['x']!);
      final bubbleY = waterTop + (fillHeight * bubble['y']!);
      final animatedY = bubbleY - (bubblePhase * bubble['speed']! * fillHeight * 0.3) % fillHeight;
      
      if (animatedY > waterTop && animatedY < waterTop + fillHeight) {
        canvas.drawCircle(
          Offset(x, animatedY),
          bubble['size']!,
          bubblePaint,
        );
        
        // Add bubble highlight
        final highlightPaint = Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(x - bubble['size']! * 0.3, animatedY - bubble['size']! * 0.3),
          bubble['size']! * 0.4,
          highlightPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(EnhancedWaterTankPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.color != color ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.bubblePhase != bubblePhase;
  }
}