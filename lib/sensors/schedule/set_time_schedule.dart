import 'package:flutter/material.dart';

class SetTimeScheduleScreen extends StatelessWidget {
  const SetTimeScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Schedule")),
      body: const Center(
        child: Text(
          "Set watering / gas schedule here",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
