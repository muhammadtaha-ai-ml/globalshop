import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lottie/lottie.dart';

import '../../devices/device_dashboard_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class HomeTab extends ConsumerStatefulWidget {
  final VoidCallback onAddDevicePressed;

  const HomeTab({
    super.key,
    required this.onAddDevicePressed,
  });

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  final List<LinearGradient> deviceGradients = [
    const LinearGradient(
      colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFFFFF9C4), Color(0xFFFFF59D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  final List<Color> deviceIconColors = [
    const Color(0xFF1976D2), // Blue
    const Color(0xFFC2185B), // Pink
    const Color(0xFF7B1FA2), // Purple
    const Color(0xFF388E3C), // Green
    const Color(0xFFF57C00), // Orange
    const Color(0xFF00796B), // Teal
    const Color(0xFFFBC02D), // Yellow
    const Color(0xFF512DA8), // Deep Purple
  ];

  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    if (user?.email != null) {
      String emailName = user!.email!.split('@')[0];
      return emailName[0].toUpperCase() + emailName.substring(1);
    }
    return 'User';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 20) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  void _navigateToDevice(Map device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeviceDashboardScreen(
          deviceId: device['deviceId'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = _getUserName();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Column(
      children: [
        // Greeting Section
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
                style: TextStyle(
                  color: textThemeColor,
                  fontSize: 30,
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
                  Text(
                    'My Devices',
                    style: TextStyle(
                      color: textThemeColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Devices Grid
        Expanded(
          child: ref.watch(devicesStreamProvider).when(
            loading: () => Center(
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
                  const SizedBox(height: 16),
                  Text(
                    'Loading your devices...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            error: (err, stack) => _emptyState(),
            data: (allDevices) {
              if (allDevices.isEmpty) {
                return _emptyState();
              }

              // Filter only active devices
              final List<MapEntry> activeDevices = allDevices.entries
                  .where((entry) => entry.value['isActive'] != false)
                  .toList();

              if (activeDevices.isEmpty) {
                return _emptyState();
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                physics: const BouncingScrollPhysics(),
                itemCount: activeDevices.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final device = activeDevices[index].value;
                  final String name = device['deviceName'] ?? '';
                  final String id = device['deviceId'] ?? '';

                  return _buildDeviceCard(
                    device: device,
                    gradient: _getDeviceGradient(name, id, isDark),
                    iconColor: _getDeviceIconColor(name, id),
                    iconData: _getDeviceIcon(name, id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getDeviceIcon(String name, String id) {
    final lowerName = name.toLowerCase();
    final lowerId = id.toLowerCase();
    
    if (lowerName.contains('gas') || lowerName.contains('biogas') || lowerId.contains('gas')) {
      return Icons.gas_meter_rounded; // Biogas/Methane monitor icon
    } else if (lowerName.contains('water') || lowerName.contains('tank') || lowerName.contains('level') || lowerName.contains('pump') || lowerName.contains('liquid') || lowerId.contains('water') || lowerId.contains('tank')) {
      return Icons.opacity_rounded; // Water droplet / liquid level icon
    } else if (lowerName.contains('bulb') || lowerName.contains('relay') || lowerName.contains('light') || lowerName.contains('switch') || lowerId.contains('bulb') || lowerId.contains('relay')) {
      return Icons.lightbulb_rounded; // Lightbulb icon
    }
    
    return Icons.sensors_rounded; // General smart sensor fallback
  }

  LinearGradient _getDeviceGradient(String name, String id, bool isDark) {
    final lowerName = name.toLowerCase();
    final lowerId = id.toLowerCase();

    if (isDark) {
      if (lowerName.contains('gas') || lowerName.contains('biogas') || lowerId.contains('gas')) {
        return const LinearGradient(
          colors: [Color(0xFF2A1B10), Color(0xFF1E2030)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else if (lowerName.contains('water') || lowerName.contains('tank') || lowerName.contains('level') || lowerName.contains('pump') || lowerName.contains('liquid') || lowerId.contains('water') || lowerId.contains('tank')) {
        return const LinearGradient(
          colors: [Color(0xFF0C2530), Color(0xFF1E2030)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else if (lowerName.contains('bulb') || lowerName.contains('relay') || lowerName.contains('light') || lowerName.contains('switch') || lowerId.contains('bulb') || lowerId.contains('relay')) {
        return const LinearGradient(
          colors: [Color(0xFF2C2510), Color(0xFF1E2030)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
      return const LinearGradient(
        colors: [Color(0xFF1E2030), Color(0xFF15161F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    if (lowerName.contains('gas') || lowerName.contains('biogas') || lowerId.contains('gas')) {
      // Premium sunset gradient for Biogas
      return const LinearGradient(
        colors: [Color(0xFFFFF3E0), Color(0xFFFFCC80)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (lowerName.contains('water') || lowerName.contains('tank') || lowerName.contains('level') || lowerName.contains('pump') || lowerName.contains('liquid') || lowerId.contains('water') || lowerId.contains('tank')) {
      // Premium cyan/blue gradient for Water Level
      return const LinearGradient(
        colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (lowerName.contains('bulb') || lowerName.contains('relay') || lowerName.contains('light') || lowerName.contains('switch') || lowerId.contains('bulb') || lowerId.contains('relay')) {
      // Premium warm yellow gradient for Bulb
      return const LinearGradient(
        colors: [Color(0xFFFFFDE7), Color(0xFFFFF59D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    // Default clean blue gradient
    return const LinearGradient(
      colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color _getDeviceIconColor(String name, String id) {
    final lowerName = name.toLowerCase();
    final lowerId = id.toLowerCase();

    if (lowerName.contains('gas') || lowerName.contains('biogas') || lowerId.contains('gas')) {
      return const Color(0xFFE65100); // Deep biogas orange
    } else if (lowerName.contains('water') || lowerName.contains('tank') || lowerName.contains('level') || lowerName.contains('pump') || lowerName.contains('liquid') || lowerId.contains('water') || lowerId.contains('tank')) {
      return const Color(0xFF006064); // Cool deep water teal/blue
    } else if (lowerName.contains('bulb') || lowerName.contains('relay') || lowerName.contains('light') || lowerName.contains('switch') || lowerId.contains('bulb') || lowerId.contains('relay')) {
      return const Color(0xFFFBC02D); // Warm amber yellow
    }

    return const Color(0xFF1976D2); // Default blue
  }

  Widget _buildDeviceCard({
    required Map device,
    required LinearGradient gradient,
    required Color iconColor,
    required IconData iconData,
  }) {
    final String name = device['deviceName'] ?? '';
    final String id = device['deviceId'] ?? '';
    
    // Determine device category
    final bool isGas = name.toLowerCase().contains('gas') || name.toLowerCase().contains('biogas') || id.toLowerCase().contains('gas');
    final bool isWater = name.toLowerCase().contains('water') || name.toLowerCase().contains('tank') || name.toLowerCase().contains('level') || name.toLowerCase().contains('pump') || name.toLowerCase().contains('liquid') || id.toLowerCase().contains('water') || id.toLowerCase().contains('tank');
    final bool isBulb = name.toLowerCase().contains('bulb') || name.toLowerCase().contains('relay') || name.toLowerCase().contains('light') || name.toLowerCase().contains('switch') || id.toLowerCase().contains('bulb') || id.toLowerCase().contains('relay');
    
    // Customize stats based on type
    final String categoryLabel = isGas
        ? "BIOGAS MONITOR"
        : (isWater
            ? "WATER LEVEL"
            : (isBulb ? "BULB AUTOMATE" : "SMART SENSOR"));

    return Hero(
      tag: 'device_${device['deviceId']}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _navigateToDevice(device),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Decorative background circular soft glow
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with Category Badge and Glowing Icon Backdrop
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Glowing concentric backdropped Icon
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  iconData,
                                  color: iconColor,
                                  size: 22,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Tech Category Label
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                categoryLabel,
                                style: TextStyle(
                                  color: iconColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),

                        // Device Nickname
                        Text(
                          name,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1A1A1A),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),

                        // Device ID
                        Text(
                          "ID: $id",
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[600],
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // High-tech Digital Readout Stream
                        StreamBuilder<DatabaseEvent>(
                          stream: isBulb
                              ? FirebaseDatabase.instance
                                  .ref('devices')
                                  .child(id)
                                  .child('relay')
                                  .onValue
                              : FirebaseDatabase.instance
                                  .ref('devices')
                                  .child(id)
                                  .child('logs')
                                  .limitToLast(1)
                                  .onValue,
                          builder: (context, snapshot) {
                            // While Firebase is connecting show a loader
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return SizedBox(
                                height: 60,
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                                    ),
                                  ),
                                ),
                              );
                            }

                            String currentReadout = isGas ? "--% Vol" : (isWater ? "--% Level" : (isBulb ? "OFF" : "Active"));
                            double currentFactor = 0.0;
                            String currentStatus = isGas ? "Connecting..." : (isWater ? "Connecting..." : (isBulb ? "Connecting..." : "Online"));
                            Color currentStatusColor = Colors.grey;

                            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                              final rawVal = snapshot.data!.snapshot.value;
                              if (isBulb) {
                                int relayVal = 0;
                                if (rawVal is Map) {
                                  relayVal = int.tryParse(rawVal['relay1']?.toString() ?? '0') ?? 0;
                                } else if (rawVal is num) {
                                  relayVal = rawVal.toInt();
                                }
                                
                                if (relayVal == 1) {
                                  currentReadout = "ON";
                                  currentFactor = 1.0;
                                  currentStatus = "Light is ON";
                                  currentStatusColor = const Color(0xFF4CAF50);
                                } else {
                                  currentReadout = "OFF";
                                  currentFactor = 0.0;
                                  currentStatus = "Light is OFF";
                                  currentStatusColor = const Color(0xFFEF5350);
                                }
                              } else if (rawVal is Map) {
                                final logsMap = Map<dynamic, dynamic>.from(rawVal);
                                final sortedKeys = logsMap.keys.toList()..sort();
                                if (sortedKeys.isNotEmpty) {
                                  final latestLog = Map<String, dynamic>.from(logsMap[sortedKeys.last] as Map);
                                  
                                  if (isWater) {
                                    final int waterLevel = int.tryParse(
                                      (latestLog['waterLevel'] ?? latestLog['WaterLevel'] ?? '-1').toString()
                                    ) ?? -1;
                                    if (waterLevel >= 0) {
                                      final double pct = waterLevel < 1 
                                          ? 0.0 
                                          : (waterLevel > 7 ? 100.0 : (waterLevel / 7) * 100);
                                      currentReadout = "${pct.toStringAsFixed(0)}% Level";
                                      currentFactor = (pct / 100.0).clamp(0.0, 1.0);
                                      final desc = (latestLog['levelDescription'] ?? latestLog['LevelDescription'] ?? '').toString();
                                      currentStatus = desc.isNotEmpty ? desc : "Tank Optimal";
                                      final descLower = currentStatus.toLowerCase();
                                      if (descLower.contains("very low")) {
                                        currentStatusColor = const Color(0xFFC62828);
                                      } else if (descLower.contains("low")) {
                                        currentStatusColor = const Color(0xFFE65100);
                                      } else if (descLower.contains("very high")) {
                                        currentStatusColor = const Color(0xFF1565C0);
                                      } else {
                                        currentStatusColor = const Color(0xFF2E7D32);
                                      }
                                    }
                                  } else if (isGas) {
                                    const excludedKeys = {'temperature', 'humidity', 'time', 'sensortype', 'deviceid'};
                                    final List<Map<String, dynamic>> gasReadings = [];

                                    for (final key in latestLog.keys) {
                                      final keyStr = key.toString().toLowerCase();
                                      if (excludedKeys.contains(keyStr)) continue;
                                      final val = latestLog[key];

                                      double gasVal = 0.0;
                                      String gasStatus = '';

                                      if (val is Map) {
                                        // Iterate inner map keys safely (Firebase returns Object? keys)
                                        for (final innerKey in val.keys) {
                                          final ik = innerKey.toString();
                                          if (ik == 'value') {
                                            gasVal = double.tryParse(val[innerKey]?.toString() ?? '0') ?? 0.0;
                                          } else if (ik == 'status') {
                                            gasStatus = val[innerKey]?.toString() ?? '';
                                          }
                                        }
                                        gasReadings.add({'name': key.toString(), 'value': gasVal, 'status': gasStatus});
                                      } else if (val is num) {
                                        // Flat numeric value — also valid
                                        gasReadings.add({'name': key.toString(), 'value': val.toDouble(), 'status': ''});
                                      }
                                    }

                                    if (gasReadings.isNotEmpty) {
                                      double totalValue = 0.0;
                                      for (var g in gasReadings) totalValue += (g['value'] as double);

                                      double methaneVal = 0.0;
                                      for (var g in gasReadings) {
                                        final kl = g['name'].toString().toLowerCase();
                                        if (kl == 'methane' || kl == 'ch4') {
                                          methaneVal = g['value'] as double;
                                        }
                                      }

                                      String methaneStatus;
                                      if (methaneVal <= 1000) {
                                        methaneStatus = 'normal';
                                      } else if (methaneVal <= 4000) {
                                        methaneStatus = 'warning';
                                      } else {
                                        methaneStatus = 'danger';
                                      }

                                      final double methanePct = totalValue > 0
                                          ? (methaneVal / totalValue) * 100
                                          : 0.0;

                                      currentReadout = "${methanePct.toStringAsFixed(1)}% Vol";
                                      currentFactor = (methanePct / 100.0).clamp(0.0, 1.0);

                                      if (methaneStatus == 'danger') {
                                        currentStatus = "Danger Methane";
                                        currentStatusColor = const Color(0xFFC62828);
                                      } else if (methaneStatus == 'warning') {
                                        currentStatus = "Warning Methane";
                                        currentStatusColor = const Color(0xFFE65100);
                                      } else {
                                        currentStatus = "Stable Methane";
                                        currentStatusColor = const Color(0xFF2E7D32);
                                      }
                                    }
                                  }

                                }
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      currentReadout.split(' ')[0],
                                      style: TextStyle(
                                        color: iconColor,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    if (currentReadout.split(' ').length > 1) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        currentReadout.split(' ')[1],
                                        style: TextStyle(
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[700],
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 5,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: currentFactor,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: iconColor,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: currentStatusColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: currentStatusColor.withOpacity(0.4),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        currentStatus,
                                        style: TextStyle(
                                          color: currentStatusColor,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
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

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF42A5F5).withOpacity(0.1),
                    const Color(0xFF1E88E5).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.devices_other_rounded,
                size: 80,
                color: Color(0xFF42A5F5),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "No Devices Yet",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Start by adding your first device\nTap the Add Device tab in the bottom bar",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E88E5).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: widget.onAddDevicePressed,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'Add Device',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
