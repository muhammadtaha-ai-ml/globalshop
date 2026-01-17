import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class WaterLevelMonitoringScreen extends StatelessWidget {
  final String deviceId;

  const WaterLevelMonitoringScreen({
    super.key,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    final logsRef = FirebaseDatabase.instance
        .ref('devices')
        .child(deviceId)
        .child('logs')
        .limitToLast(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Water Level Monitoring"),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: logsRef.onValue,
        builder: (context, snapshot) {
          // ⏳ Loading
          if (!snapshot.hasData ||
              snapshot.data!.snapshot.value == null) {
            return _emptyState();
          }

          final Map logs =
              Map<String, dynamic>.from(
                  snapshot.data!.snapshot.value as Map);

          final latestLog = logs.values.first;

          final int waterLevel = latestLog['waterLevel'] ?? 0;
          final String levelDescription =
              latestLog['levelDescription'] ?? "Unknown";
          final String time = latestLog['time'] ?? "--";

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.water_drop,
                  size: 90,
                  color: Colors.green,
                ),
                const SizedBox(height: 20),

                Text(
                  "Water Level: $waterLevel",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    levelDescription,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time,
                        size: 18,
                        color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                Text(
                  "Device ID: $deviceId",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🔹 Empty / No Data UI
  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 80,
              color: Colors.red),
          SizedBox(height: 16),
          Text(
            "No water data available",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Sensor has not sent data yet",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
