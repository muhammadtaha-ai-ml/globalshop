import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sensors/water/water_level_monitoring.dart';
import '../sensors/gas/gas_monitor_screen.dart';
import '../sensors/schedule/set_time_schedule.dart';
import '../sensors/bulb/bulb_automation_screen.dart';

class DeviceDashboardScreen extends StatefulWidget {
  final String deviceId;

  const DeviceDashboardScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<DeviceDashboardScreen> createState() => _DeviceDashboardScreenState();
}

class _DeviceDashboardScreenState extends State<DeviceDashboardScreen> {
  String? _sensorType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceType();
  }

  Future<void> _loadDeviceType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedType = prefs.getString('sensor_type_${widget.deviceId}');
      
      if (cachedType != null) {
        if (mounted) {
          setState(() {
            _sensorType = cachedType;
            _isLoading = false;
          });
        }
        return;
      }

      // Fetch root device node from database
      final deviceRef = FirebaseDatabase.instance
          .ref('devices')
          .child(widget.deviceId);
          
      final snapshot = await deviceRef.get();
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> deviceData = snapshot.value as Map<dynamic, dynamic>;
        
        // 1. Check deviceName
        final String name = (deviceData['deviceName'] ?? '').toString().toLowerCase();
        if (name.contains('bulb') || name.contains('relay') || name.contains('light') || name.contains('switch')) {
          await prefs.setString('sensor_type_${widget.deviceId}', 'bulb');
          if (mounted) {
            setState(() {
              _sensorType = 'bulb';
              _isLoading = false;
            });
          }
          return;
        }

        // 2. Check logs fallback
        final logsVal = deviceData['logs'];
        if (logsVal is Map) {
          final sortedKeys = logsVal.keys.toList()..sort();
          final latestLog = logsVal[sortedKeys.last];
          if (latestLog is Map) {
            final String? type = latestLog['sensorType']?.toString();
            if (type != null) {
              await prefs.setString('sensor_type_${widget.deviceId}', type);
              if (mounted) {
                setState(() {
                  _sensorType = type;
                  _isLoading = false;
                });
              }
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching device type: $e");
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F1016) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF1E2030) : Colors.white;
    final textThemeColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: Center(
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
                    color: Color(0xFF1E88E5),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Loading Device...',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_sensorType == null) {
      return _deviceNotFound(context);
    }

    final isWater = _sensorType!.toLowerCase().contains('water');
    final isGas = _sensorType!.toLowerCase().contains('gas');
    final isBulb = _sensorType!.toLowerCase().contains('bulb') ||
        _sensorType!.toLowerCase().contains('relay') ||
        _sensorType!.toLowerCase().contains('light') ||
        _sensorType!.toLowerCase().contains('switch');

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
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
                          const Color(0xFF42A5F5).withOpacity(isDark ? 0.2 : 0.1),
                          const Color(0xFF1E88E5).withOpacity(isDark ? 0.2 : 0.1),
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
                        colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E88E5).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.devices_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device Dashboard',
                          style: TextStyle(
                            color: textThemeColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF42A5F5)
                                .withOpacity(isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.deviceId,
                            style: TextStyle(
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Control Panel',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isWater
                        ? 'Water System'
                        : isGas
                            ? 'Gas System'
                            : isBulb
                                ? 'Bulb System'
                                : 'Device',
                    style: TextStyle(
                      color: textThemeColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF42A5F5),
                              Color(0xFF1E88E5)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Features',
                        style: TextStyle(
                          color: textThemeColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Feature Cards ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: isWater
                  ? GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.80,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _modernCard(
                          context: context,
                          title: "Water Level",
                          subtitle: "Monitor",
                          imagePath: 'assets/uploads/water_level.png',
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE8F4FD),
                              Color(0xFFD2E9FC),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          iconColor: const Color(0xFF1976D2),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  WaterLevelMonitoringScreen(
                                      deviceId: widget.deviceId),
                            ),
                          ),
                        ),
                        _modernCard(
                          context: context,
                          title: "Set Schedule",
                          subtitle: "Timer",
                          imagePath: 'assets/uploads/schedule.png',
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFDF0F4),
                              Color(0xFFFADAE5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          iconColor: const Color(0xFFC2185B),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SetTimeScheduleScreen(
                                  deviceId: widget.deviceId),
                            ),
                          ),
                        ),
                      ],
                    )
                  : (isBulb
                      ? GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.80,
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          children: [
                            _modernCard(
                              context: context,
                              title: "Bulb Automation",
                              subtitle: "Switch Control",
                              imagePath: 'assets/uploads/bulb.png',
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFFFDE7),
                                  Color(0xFFFFF9C4),
                                ],
                                begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                              ),
                              iconColor: const Color(0xFFFBC02D),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BulbAutomationScreen(
                                      deviceId: widget.deviceId),
                                ),
                              ),
                            ),
                          ],
                        )
                      : GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.80,
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          children: [
                            _modernCard(
                              context: context,
                              title: "Gas Monitor",
                              subtitle: "Safety",
                              imagePath: 'assets/uploads/gas.png',
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFEDE4F5),
                                  Color(0xFFE2D1F0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              iconColor: const Color(0xFF7B1FA2),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GasMonitorScreen(
                                      deviceId: widget.deviceId),
                                ),
                              ),
                            ),
                          ],
                        )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Device Not Found ──
  Widget _deviceNotFound(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F1016) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF1E2030) : Colors.white;
    final textThemeColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
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
                          const Color(0xFF42A5F5).withOpacity(isDark ? 0.2 : 0.1),
                          const Color(0xFF1E88E5).withOpacity(isDark ? 0.2 : 0.1),
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
                        colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E88E5).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.devices_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Device Dashboard',
                      style: TextStyle(
                        color: textThemeColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        Lottie.asset(
                          'assets/animations/404_error_not_found.json',
                          width: MediaQuery.of(context).size.width * 0.95,
                          height: MediaQuery.of(context).size.width * 0.95,
                          fit: BoxFit.contain,
                          repeat: true,
                          animate: true,
                        ),
                        Transform.translate(
                          offset: const Offset(0, -25),
                          child: Column(
                            children: [
                              Text(
                                "Device Not Found",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: textThemeColor,
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "This device is not registered\nor no sensor data available",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: secondaryTextColor,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF14223A) : const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                        Icons.info_outline_rounded,
                                        color: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
                                        size: 20),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        'Please check your device ID',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modernCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    String? imagePath,
    IconData? icon,
    required LinearGradient gradient,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    LinearGradient cardGradient = gradient;
    if (isDark) {
      if (title.toLowerCase().contains("water")) {
        cardGradient = const LinearGradient(
          colors: [Color(0xFF0C2530), Color(0xFF1E2030)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else if (title.toLowerCase().contains("schedule") || title.toLowerCase().contains("timer")) {
        cardGradient = const LinearGradient(
          colors: [Color(0xFF2D1A22), Color(0xFF1E2030)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else if (title.toLowerCase().contains("bulb") || title.toLowerCase().contains("automation")) {
        cardGradient = const LinearGradient(
          colors: [Color(0xFF2A1E08), Color(0xFF1E2030)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else {
        cardGradient = const LinearGradient(
          colors: [Color(0xFF1F1A2D), Color(0xFF1E2030)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
    }

    return Hero(
      tag: 'feature_$title',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: cardGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(isDark ? 0.02 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  // Decorative circular glow behind the illustration (Only for icons)
                  if (imagePath == null)
                    Positioned(
                      top: 15,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 95,
                          height: 95,
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),

                  // Illustration Image / Icon (Zoomed and fitted seamlessly)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    bottom: 68,
                    child: imagePath != null
                        ? Container(
                            padding: const EdgeInsets.all(4),
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Icon(
                            icon ?? Icons.settings_input_component_rounded,
                            color: iconColor.withOpacity(0.6),
                            size: 60,
                          ),
                  ),

                  // Frosted bottom glass panel
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2030).withOpacity(0.9) : Colors.white.withOpacity(0.94),
                        border: Border(
                          top: BorderSide(
                            color: isDark ? Colors.grey[800]!.withOpacity(0.4) : Colors.white.withOpacity(0.6),
                            width: 1.5,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: textThemeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  subtitle.toUpperCase(),
                                  style: TextStyle(
                                    color: iconColor,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: iconColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}