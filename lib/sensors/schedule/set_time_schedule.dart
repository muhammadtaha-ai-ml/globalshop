import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../../devices/schedule_service.dart';

class SetTimeScheduleScreen extends StatefulWidget {
  final String deviceId;

  const SetTimeScheduleScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<SetTimeScheduleScreen> createState() =>
      _SetTimeScheduleScreenState();
}

class _SetTimeScheduleScreenState extends State<SetTimeScheduleScreen>
    with SingleTickerProviderStateMixin {
  final List<TimeOfDay> _times = [];
  bool _loading = true;
  bool _hasUnsavedChanges = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedTimes();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedTimes() async {
    final saved = await ScheduleService.loadUserSchedules(widget.deviceId);
    setState(() {
      _times.clear();
      for (final t in saved) {
        final parts = t.split(':');
        if (parts.length == 2) {
          _times.add(TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          ));
        }
      }
      _loading = false;
    });
  }

  String _getTimePeriod(TimeOfDay time) {
    final h = time.hour;
    if (h >= 5 && h < 12) return 'Morning';
    if (h >= 12 && h < 17) return 'Afternoon';
    if (h >= 17 && h < 21) return 'Evening';
    return 'Night';
  }

  IconData _getTimePeriodIcon(TimeOfDay time) {
    final h = time.hour;
    if (h >= 5 && h < 12) return Icons.wb_sunny_rounded;
    if (h >= 12 && h < 17) return Icons.wb_sunny;
    if (h >= 17 && h < 21) return Icons.wb_twilight_rounded;
    return Icons.nightlight_round;
  }

  Color _getTimePeriodColor(TimeOfDay time) {
    final h = time.hour;
    if (h >= 5 && h < 12) return const Color(0xFFFF8F00);
    if (h >= 12 && h < 17) return const Color(0xFFFF5722);
    if (h >= 17 && h < 21) return const Color(0xFFE91E63);
    return const Color(0xFF5C6BC0);
  }

  List<Color> _getTimePeriodGradient(TimeOfDay time) {
    final h = time.hour;
    if (h >= 5 && h < 12) return [const Color(0xFFFF8F00), const Color(0xFFFFB300)];
    if (h >= 12 && h < 17) return [const Color(0xFFFF5722), const Color(0xFFFF8A65)];
    if (h >= 17 && h < 21) return [const Color(0xFFE91E63), const Color(0xFFF06292)];
    return [const Color(0xFF5C6BC0), const Color(0xFF7986CB)];
  }

  Future<void> _addTime() async {
    if (_times.length >= 5) {
      _showSnackBar("Maximum 5 schedules allowed", isError: true);
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6F00),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      HapticFeedback.mediumImpact();
      setState(() {
        _times.add(picked);
        _hasUnsavedChanges = true;
      });
      _showSnackBar("Time added — press Save to confirm", isError: false);
    }
  }

  Future<void> _updateTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      HapticFeedback.lightImpact();
      setState(() {
        _times[index] = picked;
        _hasUnsavedChanges = true;
      });
      _showSnackBar("Time updated — press Save to confirm", isError: false);
    }
  }

  Future<void> _save() async {
    if (_times.isEmpty) {
      _showSnackBar("Please add at least one time", isError: true);
      return;
    }

    final times = _times
        .map((t) =>
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
        .toList();

    try {
      await ScheduleService.saveSchedules(
        deviceId: widget.deviceId,
        times: times,
      );
      if (mounted) {
        HapticFeedback.selectionClick();
        setState(() => _hasUnsavedChanges = false);
        _showSnackBar("Schedule saved successfully!", isError: false);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Error: $e", isError: true);
    }
  }

  Future<void> _confirmDelete(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E2030) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF5350).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFEF5350), size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Delete Schedule?',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          content: Text(
            'This schedule will be removed. Press Save after to apply changes.',
            style: TextStyle(
                fontSize: 14, 
                color: isDark ? Colors.grey[400] : const Color(0xFF666666), 
                height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                    color: isDark ? Colors.grey[400] : const Color(0xFF666666), 
                    fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF5350),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      setState(() {
        _times.removeAt(index);
        _hasUnsavedChanges = true;
      });
      _showSnackBar("Removed — press Save to confirm", isError: false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFEF5350) : const Color(0xFF66BB6A),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1016) : const Color(0xFFFFF8F0),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F1016), const Color(0xFF15161F)]
                : [
                    const Color(0xFFFFF8F0),
                    const Color(0xFFFFFBF5),
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: _loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animations/loader.json',
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const CircularProgressIndicator(
                          color: Color(0xFFFF6F00),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Loading schedules...',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF6F00),
                      ),
                    ),
                  ],
                ),
              )
            : SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      _buildAppBar(),
                      _buildInfoBanner(),
                      Expanded(
                        child: _times.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 0),
                                physics: const BouncingScrollPhysics(),
                                itemCount: _times.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12),
                                    child: _buildTimeCard(
                                        _times[index], index),
                                  );
                                },
                              ),
                      ),
                      _buildBottomActions(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2030) : Colors.white;
    final textThemeColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6F00).withOpacity(isDark ? 0.16 : 0.08),
                  const Color(0xFFFF8F00).withOpacity(isDark ? 0.16 : 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFFE65100),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6F00).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Watering Schedule',
                  style: TextStyle(
                    color: textThemeColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_times.length}/5 time slots used',
                  style: TextStyle(
                    color: _times.length >= 5
                        ? const Color(0xFFEF5350)
                        : const Color(0xFFFF8F00),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Slot counter badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6F00).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFFF6F00).withOpacity(0.25), width: 1),
            ),
            child: Text(
              '${_times.length}/5',
              style: const TextStyle(
                color: Color(0xFFFF6F00),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4FC3F7).withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Set up to 5 automatic watering times for your device',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6F00).withOpacity(0.08),
                  isDark ? const Color(0xFFFFE0B2).withOpacity(0.05) : const Color(0xFFFFE0B2).withOpacity(0.15),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time_rounded,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "No schedules yet",
            style: TextStyle(
              fontSize: 20,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap 'Add Time' below to set your first\nautomatic watering schedule",
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(TimeOfDay t, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2030) : Colors.white;
    final textThemeColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    final period = _getTimePeriod(t);
    final icon = _getTimePeriodIcon(t);
    final color = _getTimePeriodColor(t);
    final gradient = _getTimePeriodGradient(t);
    final timeStr =
        '${t.hour % 12 == 0 ? 12 : t.hour % 12}:${t.minute.toString().padLeft(2, '0')} ${t.hour >= 12 ? 'PM' : 'AM'}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(isDark ? 0.3 : 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.03 : 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Period icon with gradient bg
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),

          // Time + period
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textThemeColor,
                    letterSpacing: 0.3,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Edit button
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(isDark ? 0.16 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => _updateTime(index),
              icon: const Icon(Icons.edit_rounded,
                  color: Color(0xFF2196F3), size: 20),
            ),
          ),
          const SizedBox(width: 8),

          // Delete button
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEF5350).withOpacity(isDark ? 0.16 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => _confirmDelete(index),
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFEF5350), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2030) : Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add Time — outlined with orange
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _addTime,
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text(
                'Add Watering Time',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF6F00),
                side: const BorderSide(
                    color: Color(0xFFFF6F00), width: 1.8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Save — filled orange, dims when no changes
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _hasUnsavedChanges ? _save : null,
              icon: const Icon(Icons.check_rounded, size: 22),
              label: Text(
                _hasUnsavedChanges ? 'Save Schedule' : 'No Changes',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6F00),
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark ? const Color(0xFF15161F) : Colors.grey[200],
                disabledForegroundColor: isDark ? Colors.grey[600] : Colors.grey[400],
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}