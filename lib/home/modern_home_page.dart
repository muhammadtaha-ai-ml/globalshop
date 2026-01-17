import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../devices/device_service.dart';
import '../devices/device_dashboard_screen.dart';

class ModernHomePage extends StatefulWidget {
  const ModernHomePage({super.key});

  @override
  State<ModernHomePage> createState() => _ModernHomePageState();
}

class _ModernHomePageState extends State<ModernHomePage> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Devices"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDeviceDialog,
          ),
        ],
      ),

      // 🔹 DRAWER
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text("Logged User"),
              accountEmail: Text(user?.email ?? ""),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
              ),
            ),
            ListTile(
              leading:
                  const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Logout",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),

      // 🔹 DEVICES
      body: StreamBuilder<DatabaseEvent>(
        stream: DeviceService.getDevices().onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.data!.snapshot.value == null) {
            return _emptyState();
          }

          final Map data =
              snapshot.data!.snapshot.value as Map;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final device =
                  data.values.elementAt(index);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DeviceDashboardScreen(
                        deviceId: device['deviceId'],
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.devices,
                          color: Colors.white,
                          size: 40),
                      const SizedBox(height: 10),
                      Text(
                        device['deviceName'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        device['deviceId'],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices_other,
              size: 80, color: Colors.green),
          SizedBox(height: 16),
          Text(
            "No devices added yet",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            "Tap + to add a new device",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showAddDeviceDialog() {
    final nameCtrl = TextEditingController();
    final idCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add New Device"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: "Device Name"),
            ),
            TextField(
              controller: idCtrl,
              decoration: const InputDecoration(
                  labelText: "Device ID"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Add"),
            onPressed: () async {
              if (nameCtrl.text.isEmpty ||
                  idCtrl.text.isEmpty) return;

              await DeviceService.addDevice(
                deviceId: idCtrl.text.trim(),
                deviceName: nameCtrl.text.trim(),
              );

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
