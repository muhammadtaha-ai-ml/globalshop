import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
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
          appBar: AppBar(
            title: Text("Device $deviceId"),
          ),
          body: GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: isWater
                ? [
                    _card(
                      context,
                      Icons.water_drop,
                      "Water Level",
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WaterLevelMonitoringScreen(
                            deviceId: deviceId,
                          ),
                        ),
                      ),
                    ),
                    _card(
                      context,
                      Icons.schedule,
                      "Set Schedule",
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SetTimeScheduleScreen(
                            deviceId: deviceId,
                          ),
                        ),
                      ),
                    ),
                  ]
                : isGas
                    ? [
                        _card(
                          context,
                          Icons.cloud,
                          "Gas Monitor",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GasMonitorScreen(
                                deviceId: deviceId,
                              ),
                            ),
                          ),
                        ),
                      ]
                    : [],
          ),
        );
      },
    );
  }

  // ❌ DEVICE NOT FOUND UI
  Widget _deviceNotFound(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Device Error")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.error_outline, size: 80, color: Colors.red),
            SizedBox(height: 16),
            Text(
              "Device not found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              "This device ID is not registered\nor no sensor data available",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
