import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:globalshop/auth/screens/login_screen.dart';
import '../providers/providers.dart';

// Tabs
import 'screens/home_tab.dart';
import 'screens/add_device_tab.dart';
import 'screens/notifications_tab.dart';
import 'screens/profile_tab.dart';
import 'screens/settings_tab.dart';

class ModernHomePage extends ConsumerStatefulWidget {
  const ModernHomePage({super.key});

  @override
  ConsumerState<ModernHomePage> createState() => _ModernHomePageState();
}

class _ModernHomePageState extends ConsumerState<ModernHomePage> {
  int _currentIndex = 0;

  // List of screens in the requested sequence:
  // 1. Home
  // 2. Alerts (Notifications)
  // 3. Add Device
  // 4. Profile
  // 5. Settings
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeTab(onAddDevicePressed: () {
        setState(() {
          _currentIndex = 2; // Switch to Add Device tab (Index 2)
        });
      }),
      const NotificationsTab(), // Alerts (Index 1)
      AddDeviceTab(onSuccess: () {
        setState(() {
          _currentIndex = 0; // Switch back to Home tab (Index 0)
        });
      }), // Add Device (Index 2)
      const ProfileTab(), // Profile (Index 3)
      const SettingsTab(), // Settings (Index 4)
    ];
  }

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

  String _getTabTitle() {
    switch (_currentIndex) {
      case 0:
        return 'GlobalShop';
      case 1:
        return 'Notifications';
      case 2:
        return 'Register Device';
      case 3:
        return 'My Profile';
      case 4:
        return 'Settings';
      default:
        return 'GlobalShop';
    }
  }

  void _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _getUserName();
    final isConnected = ref.watch(databaseConnectionProvider).value ?? true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0B10) : const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2030) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Premium Dynamic App Logo
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/icon/app_icon.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.store_rounded,
                          color: Color(0xFF1976D2),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tab Title
                Text(
                  _getTabTitle(),
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),

                // Small quick avatar / status on top right
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = 3; // Switch to profile tab (Index 3)
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF42A5F5).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFF0F4F8),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                        style: const TextStyle(
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Logout Button next to Profile Avatar in AppBar
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF5350).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEF5350),
                      size: 18,
                    ),
                    onPressed: _handleLogout,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _screens[_currentIndex],
            if (!isConnected)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: const Color(0xFFEF5350),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "You are currently offline",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2030) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: const Color(0xFF42A5F5).withOpacity(isDark ? 0.24 : 0.12),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2),
                  );
                }
                return TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return IconThemeData(
                    color: isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2),
                    size: 24,
                  );
                }
                return IconThemeData(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  size: 22,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: isDark ? const Color(0xFF1E2030) : Colors.white,
              elevation: 0,
              height: 70,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_rounded),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: (() {
                    final count = ref.watch(unreadNotificationsCountProvider).value ?? 0;
                    if (count > 0) {
                      return Badge(
                        label: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: const Color(0xFFEF5350),
                        child: const Icon(Icons.notifications_rounded),
                      );
                    }
                    return const Icon(Icons.notifications_none_rounded);
                  })(),
                  selectedIcon: const Icon(Icons.notifications_rounded),
                  label: 'Alerts',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.add_circle_outline_rounded),
                  selectedIcon: Icon(Icons.add_circle_rounded),
                  label: 'Add Device',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}