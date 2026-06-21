import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notifications/notification_service.dart';
import '../../providers/providers.dart';

class NotificationsTab extends ConsumerStatefulWidget {
  const NotificationsTab({super.key});

  @override
  ConsumerState<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends ConsumerState<NotificationsTab> {
  @override
  void initState() {
    super.initState();
    // Add beautiful test data if user doesn't have any notifications
    NotificationService.addMockNotificationsIfNeeded();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    try {
      final int ms = timestamp is int ? timestamp : int.parse(timestamp.toString());
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return DateFormat('hh:mm a • dd MMM').format(dt);
    } catch (_) {
      return "Just now";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2030) : Colors.white;
    final textThemeColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Column(
      children: [
        // Action Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "System Alerts",
                style: TextStyle(
                  color: textThemeColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await NotificationService.markAllAsRead();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.done_all_rounded, color: Colors.white),
                          const SizedBox(width: 12),
                          Text("All notifications marked as read"),
                        ],
                      ),
                      backgroundColor: const Color(0xFF5B9BD5),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
                icon: const Icon(Icons.done_all_rounded, size: 18, color: Color(0xFF1E88E5)),
                label: const Text(
                  "Mark all read",
                  style: TextStyle(
                    color: Color(0xFF1E88E5),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Notifications List
        Expanded(
          child: ref.watch(notificationsStreamProvider).when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E88E5),
              ),
            ),
            error: (err, stack) => _buildEmptyState(),
            data: (notificationsList) {
              if (notificationsList.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                physics: const BouncingScrollPhysics(),
                itemCount: notificationsList.length,
                itemBuilder: (context, index) {
                  final item = notificationsList[index];
                  final String id = item['id'] ?? '';
                  final String title = item['title'] ?? 'Alert';
                  final String body = item['body'] ?? '';
                  final bool isRead = item['isRead'] ?? false;
                  final dynamic timestamp = item['timestamp'];

                  // Dynamic color styling based on alert critical nature
                  final isWarning = title.toLowerCase().contains('alert') || 
                                    title.toLowerCase().contains('warning') || 
                                    title.toLowerCase().contains('critical') || 
                                    body.toLowerCase().contains('stable at 15%') || 
                                    body.toLowerCase().contains('critical');

                  final accentGradient = isWarning
                      ? const [Color(0xFFFF7043), Color(0xFFE64A19)]
                      : const [Color(0xFF42A5F5), Color(0xFF1E88E5)];

                  return Dismissible(
                    key: Key(id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF5350), Color(0xFFD32F2F)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.delete_sweep_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    onDismissed: (direction) async {
                      HapticFeedback.heavyImpact();
                      await NotificationService.deleteNotification(id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.delete_forever_rounded, color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(child: Text("Alert '$title' deleted permanently")),
                              ],
                            ),
                            backgroundColor: const Color(0xFFEF5350),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isRead 
                              ? (isDark ? Colors.grey[800]! : Colors.grey[200]!)
                              : accentGradient[0].withOpacity(0.15),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.015),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // Glowing Premium Left Accent Line
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 4.5,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: accentGradient,
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Subtle background glow for unread items
                            if (!isRead)
                              Positioned.fill(
                                child: Container(
                                  color: accentGradient[0].withOpacity(0.015),
                                ),
                              ),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Glowing Concentric Icon Container
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isRead 
                                          ? (isDark ? Colors.grey[900]! : const Color(0xFFF5F7FA))
                                          : accentGradient[0].withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isRead 
                                          ? Icons.notifications_none_rounded 
                                          : Icons.notifications_active_rounded,
                                      color: isRead 
                                          ? Colors.grey[600] 
                                          : accentGradient[0],
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Alert Content Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: TextStyle(
                                                  color: textThemeColor,
                                                  fontSize: 15.5,
                                                  fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                                                  letterSpacing: -0.1,
                                                ),
                                              ),
                                            ),
                                            if (!isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(colors: accentGradient),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          body,
                                          style: TextStyle(
                                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                                            fontSize: 13,
                                            height: 1.35,
                                            fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 12,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatTimestamp(timestamp),
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF42A5F5).withOpacity(0.04),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(
                  Icons.notifications_off_rounded,
                  size: 48,
                  color: Color(0xFF42A5F5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "All Clear!",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You have no notifications or alerts",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
