import 'package:flutter/material.dart';

class GasMonitorScreen extends StatelessWidget {
  const GasMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gas Monitoring")),
      body: const Center(
        child: Text(
          "Gas Sensor Live Readings\n(ESP32 → Firebase)",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
