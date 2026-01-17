import 'package:flutter/material.dart';

class SetTimeScheduleScreen extends StatelessWidget {
  final String deviceId;

  const SetTimeScheduleScreen({
    super.key,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Schedule"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.schedule,
              size: 80,
              color: Colors.blue,
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
              "Set watering / gas schedule here",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
