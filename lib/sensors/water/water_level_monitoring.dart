import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';

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
  late AnimationController _ringController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _ringAnimation;
  List<Map<String, dynamic>> _allLogs = [];

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );
    _scaleController.forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _ringAnimation = CurvedAnimation(
      parent: _ringController,
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
    _ringController.dispose();
    super.dispose();
  }

  double _calculatePercentage(int waterLevel) {
    if (waterLevel < 1) return 0;
    if (waterLevel > 7) return 100;
    return (waterLevel / 7) * 100;
  }

  String _getLevelDescription(int waterLevel) {
    switch (waterLevel) {
      case 1: return "VERY LOW";
      case 2: return "LOW";
      case 3: return "MEDIUM LOW";
      case 4: return "MEDIUM";
      case 5: return "MEDIUM HIGH";
      case 6: return "HIGH";
      case 7: return "VERY HIGH";
      default: return "Unknown";
    }
  }

  Color _getLevelColor(int waterLevel) {
    return const Color(0xFF4FC3F7);
  }

  Color _getPercentageColor(int waterLevel) {
    if (waterLevel <= 2) return const Color(0xFF29B6F6);
    if (waterLevel <= 4) return const Color(0xFF0288D1);
    return const Color(0xFF01579B);
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
        .limitToLast(30);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0B10) : const Color(0xFFF8F9FA),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0F1016),
                    const Color(0xFF141622),
                    const Color(0xFF1A1D30),
                  ]
                : [
                    const Color(0xFFF0F9FF),
                    const Color(0xFFFAFDFF),
                    const Color(0xFFFFFFFF),
                    const Color(0xFFF5FAFF),
                  ],
          ),
        ),
        child: StreamBuilder<DatabaseEvent>(
          stream: logsRef.onValue,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return _buildLoadingState();
            }

            final Map logs = Map<String, dynamic>.from(
                snapshot.data!.snapshot.value as Map);
            final sortedKeys = logs.keys.toList()..sort();
            final latestLog = logs[sortedKeys.last];
            final int waterLevel = int.tryParse(latestLog['waterLevel'].toString()) ?? 0;
            final String time = latestLog['time'] ?? "--";
            final double percentage = _calculatePercentage(waterLevel);
            final String levelDescription = _getLevelDescription(waterLevel);
            final Color levelColor = _getLevelColor(waterLevel);
            final Color percentColor = _getPercentageColor(waterLevel);
            final IconData levelIcon = _getLevelIcon(waterLevel);

            // Store all logs for history chart
            _allLogs = sortedKeys
                .map((k) => Map<String, dynamic>.from(logs[k] as Map))
                .toList();

            if (waterLevel == 1) {
              Future.microtask(() {
                SystemSound.play(SystemSoundType.alert);
                HapticFeedback.vibrate();
              });
            }

            return SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildModernAppBar(context),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: _buildWaterTankCard(
                                percentage,
                                levelColor,
                                percentColor,
                                waterLevel,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildStatusCard(
                              levelDescription,
                              levelColor,
                              levelIcon,
                            ),
                            const SizedBox(height: 10),
                            _buildDateTimeRow(time),
                            if (_allLogs.length > 1) ...[  
                              const SizedBox(height: 16),
                              _buildWaterHistoryChart(),
                            ],
                            const SizedBox(height: 16),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2030) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Water Monitor',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
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
    Color percentColor,
    int waterLevel,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _ringAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E2030), const Color(0xFF15161F)]
                  : [Colors.white, const Color(0xFFF0F9FF)],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: levelColor.withOpacity(isDark 
                  ? (0.3 + _ringAnimation.value * 0.3) 
                  : (0.5 + _ringAnimation.value * 0.2)), 
              width: 2.2,
            ),
            boxShadow: [
              // Neon cyan glowing ring – pulses
              BoxShadow(
                color: levelColor.withOpacity(isDark 
                    ? (0.15 + _ringAnimation.value * 0.25) 
                    : (0.35 + _ringAnimation.value * 0.25)),
                blurRadius: 24 + _ringAnimation.value * 16,
                spreadRadius: 2 + _ringAnimation.value * 5,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left: BIGGER tank ──
          AnimatedBuilder(
            animation: Listenable.merge([_waveController, _bubbleController]),
            builder: (context, child) {
              return CustomPaint(
                // Increased from Size(130, 240) → Size(160, 290)
                size: const Size(160, 290),
                painter: EnhancedWaterTankPainter(
                  percentage: percentage,
                  color: levelColor,
                  wavePhase: _waveController.value,
                  bubblePhase: _bubbleController.value,
                ),
              );
            },
          ),

          const SizedBox(width: 16),

          // ── Right: Stats ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: levelColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: levelColor.withOpacity(
                                0.2 + _glowAnimation.value * 0.15),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.water_drop_rounded,
                        size: 32,
                        color: levelColor,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                Text(
                  'Water Level',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 6),

                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: percentage),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Text(
                      '${value.toInt()}%',
                      style: TextStyle(
                        fontSize: 58,
                        fontWeight: FontWeight.w900,
                        color: percentColor,
                        letterSpacing: -2,
                        height: 1,
                        shadows: [
                          Shadow(
                            color: percentColor.withOpacity(0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                Container(
                  height: 1.5,
                  width: 60,
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    String levelDescription,
    Color levelColor,
    IconData levelIcon,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            levelColor.withOpacity(0.15),
            levelColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: levelColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [levelColor, levelColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: levelColor.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(levelIcon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Water Status',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  levelDescription,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: levelColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: levelColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded, color: levelColor, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeRow(String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          const SizedBox(width: 12),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2030) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gradient[0].withOpacity(isDark ? 0.25 : 0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(isDark ? 0.02 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: gradient,
            ).createShader(bounds),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white, // fallback
                letterSpacing: 0.2,
              ),
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
          Lottie.asset(
            'assets/animations/loader.json',
            width: 160,
            height: 160,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const CircularProgressIndicator(
                color: Color(0xFF4FC3F7),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Loading Water Data...',
            style: TextStyle(
              color: Color(0xFF4FC3F7),
              fontSize: 20,
              fontWeight: FontWeight.w800,
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
          'Jan','Feb','Mar','Apr','May','Jun',
          'Jul','Aug','Sep','Oct','Nov','Dec'
        ];
        return "${parts[2]} ${months[int.parse(parts[1]) - 1]} ${parts[0]}";
      }
      return time;
    } catch (e) { return time; }
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
    } catch (e) { return time; }
  }

  Widget _buildWaterHistoryChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const levelColor = Color(0xFF4FC3F7);

    final List<FlSpot> spots = [];
    for (int i = 0; i < _allLogs.length; i++) {
      final log = _allLogs[i];
      final level = int.tryParse(log['waterLevel']?.toString() ?? '');
      if (level != null) {
        final pct = _calculatePercentage(level);
        spots.add(FlSpot(i.toDouble(), pct));
      }
    }

    if (spots.length < 2) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2030) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: levelColor.withOpacity(isDark ? 0.25 : 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(isDark ? 0.06 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Water Level History',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${spots.length} readings',
                  style: const TextStyle(
                    color: Color(0xFF29B6F6),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.12),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}%',
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => isDark ? const Color(0xFF1A2035) : Colors.white,
                    getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                      '${s.y.toStringAsFixed(1)}%',
                      const TextStyle(
                        color: Color(0xFF4FC3F7),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    )).toList(),
                  ),
                  handleBuiltInTouches: true,
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: const Color(0xFF29B6F6),
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: spots.length <= 10,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFF29B6F6),
                        strokeColor: isDark ? const Color(0xFF1E2030) : Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF29B6F6).withOpacity(isDark ? 0.25 : 0.18),
                          const Color(0xFF29B6F6).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.5),
          color.withOpacity(0.2),
          color.withOpacity(0.5),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final tankRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.02,
        size.width * 0.84,
        size.height * 0.96,
      ),
      const Radius.circular(36),
    );
    canvas.drawRRect(tankRect, outlinePaint);

    final bgPaint = Paint()
      ..color = color.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(tankRect, bgPaint);

    // Draw calibration tick marks on the inner edges of the tank cylinder
    final tickPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 1.5;
    final activeTickPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2.5;

    for (int i = 1; i <= 4; i++) {
      final y = size.height * 0.02 + (size.height * 0.96) * (1 - i / 5);
      final isLvlActive = (percentage / 100) >= (i / 5);
      
      // Left side ticks
      canvas.drawLine(
        Offset(size.width * 0.08, y),
        Offset(size.width * 0.18, y),
        isLvlActive ? activeTickPaint : tickPaint,
      );
      
      // Right side ticks
      canvas.drawLine(
        Offset(size.width * 0.92, y),
        Offset(size.width * 0.82, y),
        isLvlActive ? activeTickPaint : tickPaint,
      );
    }

    if (percentage > 0) {
      final fillHeight = (size.height * 0.96) * (percentage / 100);
      final waterTop = size.height * 0.98 - fillHeight;

      final backdropPath = Path();
      backdropPath.moveTo(size.width * 0.08, size.height * 0.98);
      backdropPath.lineTo(size.width * 0.08, waterTop + 14);

      for (double i = 0; i <= size.width * 0.84; i++) {
        final x = size.width * 0.08 + i;
        final wave1 = math.sin((i / 18) - (wavePhase * 1.5 * math.pi)) * 6;
        final wave2 = math.cos((i / 12) + (wavePhase * 2.2 * math.pi)) * 4;
        final y = waterTop + 14 + wave1 + wave2;
        backdropPath.lineTo(x, y);
      }

      backdropPath.lineTo(size.width * 0.92, size.height * 0.98);
      backdropPath.close();

      final wavePath = Path();
      wavePath.moveTo(size.width * 0.08, size.height * 0.98);
      wavePath.lineTo(size.width * 0.08, waterTop + 10);

      for (double i = 0; i <= size.width * 0.84; i++) {
        final x = size.width * 0.08 + i;
        final wave1 = math.sin((i / 15) + (wavePhase * 2 * math.pi)) * 8;
        final wave2 = math.sin((i / 22) - (wavePhase * 2 * math.pi)) * 5;
        final y = waterTop + 10 + wave1 + wave2;
        wavePath.lineTo(x, y);
      }

      wavePath.lineTo(size.width * 0.92, size.height * 0.98);
      wavePath.close();

      canvas.save();
      canvas.clipRRect(tankRect);

      final backdropPaint = Paint()
        ..color = color.withOpacity(0.22)
        ..style = PaintingStyle.fill;
      canvas.drawPath(backdropPath, backdropPaint);

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.35),
            color.withOpacity(0.60),
            color.withOpacity(0.80),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, waterTop, size.width, fillHeight));

      canvas.drawPath(wavePath, fillPaint);

      if (percentage > 15) {
        _drawBubbles(canvas, size, waterTop, fillHeight);
      }

      final shimmerPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.35),
            Colors.transparent,
            Colors.white.withOpacity(0.2),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 0.65, 1.0],
        ).createShader(tankRect.outerRect);

      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.08, waterTop, size.width * 0.84, fillHeight),
        shimmerPaint,
      );

      canvas.restore();
    }
  }

  void _drawBubbles(Canvas canvas, Size size, double waterTop, double fillHeight) {
    final bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final bubbles = [
      {'x': 0.25, 'y': 0.7, 'size': 5.0, 'speed': 1.0},
      {'x': 0.45, 'y': 0.5, 'size': 3.5, 'speed': 1.5},
      {'x': 0.65, 'y': 0.8, 'size': 4.0, 'speed': 0.8},
      {'x': 0.35, 'y': 0.3, 'size': 3.0, 'speed': 1.2},
      {'x': 0.55, 'y': 0.6, 'size': 4.0, 'speed': 1.1},
    ];

    for (var bubble in bubbles) {
      final x = size.width * 0.08 + (size.width * 0.84 * bubble['x']!);
      final bubbleY = waterTop + (fillHeight * bubble['y']!);
      final animatedY = bubbleY -
          (bubblePhase * bubble['speed']! * fillHeight * 0.3) % fillHeight;

      if (animatedY > waterTop && animatedY < waterTop + fillHeight) {
        canvas.drawCircle(Offset(x, animatedY), bubble['size']!, bubblePaint);
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