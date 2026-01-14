import 'package:flutter/material.dart';

class WaterLevelMonitoringScreen extends StatelessWidget {
  const WaterLevelMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Water Level Monitoring")),
      body: const Center(
        child: Text(
          "Water Level Sensor Data\n(Realtime Firebase coming next)",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
