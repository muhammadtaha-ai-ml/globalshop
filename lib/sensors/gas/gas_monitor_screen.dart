import 'package:flutter/material.dart';

class GasMonitorScreen extends StatelessWidget {
  final String deviceId;

  const GasMonitorScreen({
    super.key,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gas Monitoring"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            Text(
              "Device ID: $deviceId",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Gas Sensor Live Readings\n(ESP32 → Firebase)",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
