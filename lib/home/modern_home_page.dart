import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../sensors/water/water_level_monitoring.dart';
import '../sensors/gas/gas_monitor_screen.dart';
import '../sensors/schedule/set_time_schedule.dart';

class ModernHomePage extends StatefulWidget {
  const ModernHomePage({super.key});

  @override
  State<ModernHomePage> createState() => _ModernHomePageState();
}

class _ModernHomePageState extends State<ModernHomePage>
    with TickerProviderStateMixin {

  late AnimationController _headerController;
  late Animation<double> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerSlide = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );

    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      // 🔹 APP BAR WITH MENU
      appBar: AppBar(
        title: const Text("GeoTech 5000"),
      ),

      // 🔹 DRAWER
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text("Logged User"),
              accountEmail: Text(user?.email ?? "No Email"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40),
              ),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
              ),
            ),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Logout",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context); // close drawer
                await FirebaseAuth.instance.signOut();
                // ❌ No navigation needed
                // AuthWrapper will redirect to LoginScreen
              },
            ),
          ],
        ),
      ),

      // 🔹 BODY
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Monitoring Dashboard",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _card(
                    context,
                    icon: Icons.water_drop,
                    title: "Water Level",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WaterLevelMonitoringScreen(),
                      ),
                    ),
                  ),
                  _card(
                    context,
                    icon: Icons.schedule,
                    title: "Set Schedule",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SetTimeScheduleScreen(),
                      ),
                    ),
                  ),
                  _card(
                    context,
                    icon: Icons.analytics,
                    title: "Gas Monitor",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GasMonitorScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 40),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
