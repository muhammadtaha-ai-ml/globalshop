import 'package:flutter/material.dart';
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
    with TickerProviderStateMixin {
  final List<TimeOfDay> _times = [];
  bool _loading = true;
  bool _hasUnsavedChanges = false; // Track if there are unsaved changes
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedTimes();

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    // Pulse animation for add button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedTimes() async {
    final saved = await ScheduleService.loadUserSchedules(widget.deviceId);

    setState(() {
      _times.clear();
      for (final t in saved) {
        final parts = t.split(':');
        if (parts.length == 2) {
          _times.add(
            TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            ),
          );
        }
      }
      _loading = false;
    });
  }

  String _getTimePeriod(TimeOfDay time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) {
      return 'Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Evening';
    } else {
      return 'Night';
    }
  }

  IconData _getTimePeriodIcon(TimeOfDay time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) {
      return Icons.wb_sunny_rounded;
    } else if (hour >= 12 && hour < 17) {
      return Icons.wb_sunny;
    } else if (hour >= 17 && hour < 21) {
      return Icons.wb_twilight_rounded;
    } else {
      return Icons.nightlight_round;
    }
  }

  List<Color> _getTimePeriodGradient(TimeOfDay time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) {
      return [const Color(0xFFFFA726), const Color(0xFFFFB74D)];
    } else if (hour >= 12 && hour < 17) {
      return [const Color(0xFFFF7043), const Color(0xFFFF8A65)];
    } else if (hour >= 17 && hour < 21) {
      return [const Color(0xFFEC407A), const Color(0xFFF06292)];
    } else {
      return [const Color(0xFF5C6BC0), const Color(0xFF7986CB)];
    }
  }

  Color _getTimePeriodBgColor(TimeOfDay time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) {
      return const Color(0xFFFFF3E0);
    } else if (hour >= 12 && hour < 17) {
      return const Color(0xFFFFE0B2);
    } else if (hour >= 17 && hour < 21) {
      return const Color(0xFFFCE4EC);
    } else {
      return const Color(0xFFE8EAF6);
    }
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
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _times.add(picked);
        _hasUnsavedChanges = true; // Mark as unsaved
      });
      _showSnackBar("Time added! Press 'Save Schedule' to confirm", isError: false);
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
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _times[index] = picked;
        _hasUnsavedChanges = true; // Mark as unsaved
      });
      _showSnackBar("Time updated! Press 'Save Schedule' to confirm", isError: false);
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
        setState(() {
          _hasUnsavedChanges = false; // Reset after successful save
        });
        _showSnackBar("Schedule saved successfully!", isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Error: $e", isError: true);
      }
    }
  }

  Future<void> _confirmDelete(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Schedule?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this watering schedule?\n\nNote: After deleting, you must press the "Save Schedule" button to permanently save the changes.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
            height: 1.5,
          ),
        ),
        actions: [
          // Cancel Button
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF666666),
              ),
            ),
          ),
          // Delete Button
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF5350), Color(0xFFE53935)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF5350).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _times.removeAt(index);
        _hasUnsavedChanges = true; // Mark as unsaved
      });
      _showSnackBar("Schedule removed! Press 'Save Schedule' to confirm", isError: false);
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
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFEF5350)
            : const Color(0xFF66BB6A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF8E1),
              Color(0xFFFFFBF0),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: _loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6F00).withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF6F00),
                        ),
                        strokeWidth: 4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Loading schedules...',
                      style: TextStyle(
                        fontSize: 16,
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              children: [
                                // Premium App Bar - STANDARDIZED SIZE (same as device_dashboard_screen.dart)
                                _buildAppBar(),

                                const SizedBox(height: 12),

                                // Info Card
                                _buildInfoCard(),

                                const SizedBox(height: 12),

                                // Times List
                                if (_times.isEmpty)
                                  Expanded(child: _buildEmptyState())
                                else
                                  SizedBox(
                                    height: constraints.maxHeight * 0.45,
                                    child: ListView.separated(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      itemCount: _times.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 14),
                                      itemBuilder: (context, index) {
                                        final t = _times[index];
                                        return TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          duration: Duration(
                                            milliseconds: 400 + (index * 100),
                                          ),
                                          curve: Curves.easeOutBack,
                                          builder: (context, value, child) {
                                            final clampedValue = value.clamp(0.0, 1.0);
                                            return Transform.scale(
                                              scale: clampedValue,
                                              child: Opacity(
                                                opacity: clampedValue,
                                                child: _buildTimeCard(t, index),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),

                                const SizedBox(height: 12),

                                // Add Button
                                _buildAddButton(),

                                const SizedBox(height: 12),

                                // Save Button
                                _buildSaveButton(),

                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF42A5F5).withOpacity(0.1),
                  const Color(0xFF1E88E5).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF1976D2),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),

          // Device Icon
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

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Watering Schedule',
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0B2).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_times.length}/5 scheduled',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4FC3F7),
            Color(0xFF29B6F6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4FC3F7).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Scheduling',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Set up to 5 automatic watering times',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6F00).withOpacity(0.1),
                  const Color(0xFFFFE0B2).withOpacity(0.2),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time_rounded,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No schedules yet",
            style: TextStyle(
              fontSize: 22,
              color: Colors.grey[700],
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the button below to add your first schedule",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Color.lerp(
                  const Color(0xFFFF6F00).withOpacity(0.2),
                  const Color(0xFFFF6F00).withOpacity(0.4),
                  _pulseAnimation.value,
                )!,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6F00)
                      .withOpacity(0.1 + _pulseAnimation.value * 0.1),
                  blurRadius: 20 + _pulseAnimation.value * 5,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _addTime,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFFFF6F00),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Add Watering Time',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF6F00),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Opacity(
        opacity: _hasUnsavedChanges ? 1.0 : 0.5, // Dim when disabled
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hasUnsavedChanges
                  ? [const Color(0xFFFF6F00), const Color(0xFFFF8F00)]
                  : [Colors.grey[400]!, Colors.grey[500]!], // Grey when disabled
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: _hasUnsavedChanges
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF6F00).withOpacity(0.5),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : [], // No shadow when disabled
          ),
          child: ElevatedButton(
            onPressed: _hasUnsavedChanges ? _save : null, // Disable when no changes
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Save Schedule',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCard(TimeOfDay t, int index) {
    final period = _getTimePeriod(t);
    final icon = _getTimePeriodIcon(t);
    final gradient = _getTimePeriodGradient(t);
    final bgColor = _getTimePeriodBgColor(t);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: gradient[0].withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Time Period Icon with gradient
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(width: 18),

          // Time Display
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t.hour % 12 == 0 ? 12 : t.hour % 12}:${t.minute.toString().padLeft(2, '0')} ${t.hour >= 12 ? 'PM' : 'AM'}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: gradient[0],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Edit Button
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF2196F3)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => _updateTime(index),
            ),
          ),
          const SizedBox(width: 12),

          // Delete Button
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF5350), Color(0xFFE53935)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF5350).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.delete_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => _confirmDelete(index),
            ),
          ),
        ],
      ),
    );
  }
}