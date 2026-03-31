import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lottie/lottie.dart';

import '../sensors/water/water_level_monitoring.dart';
import '../sensors/gas/gas_monitor_screen.dart';
import '../sensors/schedule/set_time_schedule.dart';

class DeviceDashboardScreen extends StatelessWidget {
  final String deviceId;

  const DeviceDashboardScreen({
    super.key,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    final logsRef = FirebaseDatabase.instance
        .ref('devices')
        .child(deviceId)
        .child('logs');

    return FutureBuilder<DataSnapshot>(
      future: logsRef.limitToLast(1).get(),
      builder: (context, snapshot) {
        // ⏳ loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E88E5).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Loading Device...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ❌ device not found OR no logs
        if (!snapshot.hasData || snapshot.data!.value == null) {
          return _deviceNotFound(context);
        }

        final Map logs =
            Map<String, dynamic>.from(snapshot.data!.value as Map);

        final latestLog = logs.values.first;
        final sensorType = latestLog['sensorType'];

        if (sensorType == null) {
          return _deviceNotFound(context);
        }

        final isWater =
            sensorType.toString().toLowerCase().contains('water');
        final isGas =
            sensorType.toString().toLowerCase().contains('gas');

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SafeArea(
            child: Column(
              children: [
                // Premium App Bar
                Container(
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
                      // Back Button
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
                      
                      // Device Icon
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
                        child: const Icon(
                          Icons.devices_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Device Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Device Dashboard',
                              style: TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF42A5F5).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                deviceId,
                                style: TextStyle(
                                  color: Colors.grey[700],
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

                // Header Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Control Panel',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isWater ? 'Water System' : isGas ? 'Gas System' : 'Device',
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
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
                                colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Features',
                            style: TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Feature Cards Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: isWater
                        ? GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.85,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _modernCard(
                                context: context,
                                title: "Water Level",
                                subtitle: "Monitor",
                                imagePath: 'assets/uploads/water_level.png',
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                iconColor: const Color(0xFF1976D2),
                                imageBackgroundColor: const Color(0xFFE3F2FD),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WaterLevelMonitoringScreen(
                                      deviceId: deviceId,
                                    ),
                                  ),
                                ),
                              ),
                              _modernCard(
                                context: context,
                                title: "Set Schedule",
                                subtitle: "Timer",
                                imagePath: 'assets/uploads/schedule.png',
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                iconColor: const Color(0xFFC2185B),
                                imageBackgroundColor: const Color(0xFFFCE4EC),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SetTimeScheduleScreen(
                                      deviceId: deviceId,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : isGas
                            ? GridView.count(
                                crossAxisCount: 1,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.95,
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.symmetric(
                                  horizontal: MediaQuery.of(context).size.width * 0.15,
                                ),
                                children: [
                                  _modernCard(
                                    context: context,
                                    title: "Gas Monitor",
                                    subtitle: "Safety",
                                    imagePath: null,
                                    icon: Icons.cloud_outlined,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    iconColor: const Color(0xFF7B1FA2),
                                    imageBackgroundColor: const Color(0xFFF3E5F5),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => GasMonitorScreen(
                                          deviceId: deviceId,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Text(
                                  'No features available',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ❌ DEVICE NOT FOUND UI WITH LOTTIE ANIMATION - OPTIMIZED SPACING
  Widget _deviceNotFound(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Premium App Bar - CONSISTENT WITH SUCCESS STATE
            Container(
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
                  // Back Button
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
                  
                  // Device Icon
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
                    child: const Icon(
                      Icons.devices_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Title - SAME AS SUCCESS STATE
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device Dashboard',
                          style: TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Error State with Lottie Animation - REDUCED SPACING & SMALLER SIZE
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Top spacing - minimal
                        const SizedBox(height: 30),
                        
                        // Lottie Animation - LARGE SIZE
                        Lottie.asset(
                          'assets/animations/404_error_not_found.json',
                          width: MediaQuery.of(context).size.width * 0.95,
                          height: MediaQuery.of(context).size.width * 0.95,
                          fit: BoxFit.contain,
                          repeat: true,
                          animate: true,
                        ),
                        
                        // NEGATIVE MARGIN - TEXT CHIPKA HUA EXACTLY LIKE PICTURE 1!
                        Transform.translate(
                          offset: const Offset(0, -25), // Pull text UP into animation
                          child: Column(
                            children: [
                              // Error Title - iOS style
                              const Text(
                                "Device Not Found",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              // ULTRA MINIMAL spacing
                              const SizedBox(height: 2),
                              
                              // Error Description - iOS style secondary text
                              Text(
                                "This device is not registered\nor no sensor data available",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              // ULTRA MINIMAL spacing
                              const SizedBox(height: 8),
                              
                              // Info Card - iOS style
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      color: Color(0xFF1976D2),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        'Please check your device ID',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: const Color(0xFF1976D2),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.1,
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
                        
                        // Bottom spacing
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
    required Color imageBackgroundColor,
    required VoidCallback onTap,
  }) {
    return Hero(
      tag: 'feature_$title',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Full Card Background Image/Icon
                  if (imagePath != null)
                    Container(
                      decoration: BoxDecoration(
                        gradient: gradient,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  else if (icon != null)
                    Container(
                      decoration: BoxDecoration(
                        gradient: gradient,
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: iconColor.withOpacity(0.3),
                          size: 100,
                        ),
                      ),
                    ),
                  
                  // Gradient Overlay for Text Readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          
                          // Subtitle Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                color: iconColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
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