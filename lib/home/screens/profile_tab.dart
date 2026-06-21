import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globalshop/auth/screens/login_screen.dart';
import 'package:lottie/lottie.dart';
import '../../providers/providers.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  String _getUserInitials(String name) {
    if (name.isEmpty) return "GS";
    final parts = name.trim().split(" ");
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? "";
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return ref.watch(userStreamProvider).when(
      loading: () => Center(
        child: Lottie.asset(
          'assets/animations/loader.json',
          width: 160,
          height: 160,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const CircularProgressIndicator(
              color: Color(0xFF1E88E5),
            );
          },
        ),
      ),
      error: (err, stack) => const Center(
        child: Text("Error loading profile information"),
      ),
      data: (userData) {
        final name = userData['name'] ?? user?.displayName ?? "GlobalShop User";
        final email = userData['email'] ?? user?.email ?? "No Email";
        final phone = userData['phone'] ?? "No Phone";
        final Map? devices = userData['devices'] as Map?;
        final activeDevicesCount = devices == null
            ? 0
            : devices.entries.where((e) => e.value['isActive'] != false).length;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Avatar with premium neon radial glowing background
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF7E57C2), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F1016) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: isDark ? const Color(0xFF1E2030) : const Color(0xFFF3E5F5),
                      child: Text(
                        _getUserInitials(name),
                        style: TextStyle(
                          color: isDark ? const Color(0xFFB39DDB) : const Color(0xFF7E57C2),
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // User Name (Luxury Typography)
                Text(
                  name,
                  style: TextStyle(
                    color: textThemeColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 6),

                // Email badge with futuristic outline & glow
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7E57C2).withOpacity(isDark ? 0.15 : 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF7E57C2).withOpacity(isDark ? 0.4 : 0.15),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    email,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFB39DDB) : const Color(0xFF7E57C2),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Metrics Row with Concentric glowing rings
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        isDark: isDark,
                        icon: Icons.devices_rounded,
                        value: activeDevicesCount.toString(),
                        label: "Active Monitors",
                        color: const Color(0xFF7E57C2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        isDark: isDark,
                        icon: Icons.verified_user_rounded,
                        value: "Verified",
                        label: "Account Status",
                        color: const Color(0xFF42A5F5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // Details List Header
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7E57C2), Color(0xFF42A5F5)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Account Information",
                      style: TextStyle(
                        color: textThemeColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildInfoTile(
                  isDark: isDark,
                  icon: Icons.person_outline_rounded,
                  label: "Full Name",
                  value: name,
                  color: const Color(0xFF7E57C2),
                ),
                _buildInfoTile(
                  isDark: isDark,
                  icon: Icons.phone_android_rounded,
                  label: "Phone Number",
                  value: phone,
                  color: const Color(0xFF42A5F5),
                ),
                _buildInfoTile(
                  isDark: isDark,
                  icon: Icons.fingerprint_rounded,
                  label: "User UID",
                  value: uid,
                  color: const Color(0xFF66BB6A),
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: uid));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.copy_all_rounded, color: Colors.white),
                            SizedBox(width: 12),
                            Text("UID copied to clipboard"),
                          ],
                        ),
                        backgroundColor: const Color(0xFF323232),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 36),

                // Logout Button (Highly Premium Red Glass Accent)
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2030) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFEF5350).withOpacity(isDark ? 0.4 : 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF5350).withOpacity(isDark ? 0.01 : 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TextButton.icon(
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF5350), size: 20),
                    label: const Text(
                      "Log Out",
                      style: TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required bool isDark,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2030) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.25 : 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.01 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onCopy,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2030) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.2 : 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: Icon(Icons.copy_rounded, color: isDark ? const Color(0xFFB39DDB) : const Color(0xFF7E57C2), size: 20),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E2030) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : const Color(0xFF666666),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : const Color(0xFF1A1A1A),
                ),
              ),
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
        );
      },
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
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
