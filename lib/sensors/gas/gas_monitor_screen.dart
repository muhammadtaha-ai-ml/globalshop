import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class GasMonitorScreen extends StatefulWidget {
  final String deviceId;

  const GasMonitorScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<GasMonitorScreen> createState() => _GasMonitorScreenState();
}

class _GasMonitorScreenState extends State<GasMonitorScreen>
    with SingleTickerProviderStateMixin {
  late final DatabaseReference _logsRef;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _logsRef = FirebaseDatabase.instance
        .ref('devices')
        .child(widget.deviceId)
        .child('logs');

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  _StatusConfig _statusConfig(String? status) {
    switch (status?.toLowerCase()) {
      case 'normal':
        return _StatusConfig(
          color: const Color(0xFF2E7D32),
          bgColor: const Color(0xFFE8F5E9),
          icon: Icons.check_circle_rounded,
          label: 'Normal',
        );
      case 'warning':
        return _StatusConfig(
          color: const Color(0xFFE65100),
          bgColor: const Color(0xFFFFF3E0),
          icon: Icons.warning_rounded,
          label: 'Warning',
        );
      case 'danger':
      case 'critical':
        return _StatusConfig(
          color: const Color(0xFFC62828),
          bgColor: const Color(0xFFFFEBEE),
          icon: Icons.dangerous_rounded,
          label: 'Danger',
        );
      default:
        return _StatusConfig(
          color: Colors.grey,
          bgColor: const Color(0xFFF5F5F5),
          icon: Icons.help_outline_rounded,
          label: '--',
        );
    }
  }

  _GasConfig _gasConfig(String name) {
    switch (name.toLowerCase()) {
      case 'co2':
        return _GasConfig(
          icon: Icons.cloud_outlined,
          gradient: const LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconGradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          ),
          color: const Color(0xFF1976D2),
          label: 'Carbon\nDioxide',
          shortLabel: 'CO₂',
          unit: 'ppm',
        );
      case 'methane':
        return _GasConfig(
          icon: Icons.local_fire_department_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconGradient: const LinearGradient(
            colors: [Color(0xFFE65100), Color(0xFFFFB300)],
          ),
          color: const Color(0xFFF57C00),
          label: 'Methane',
          shortLabel: 'CH₄',
          unit: 'ppm',
        );
      case 'so2':
        return _GasConfig(
          icon: Icons.science_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconGradient: const LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
          ),
          color: const Color(0xFF7B1FA2),
          label: 'Sulfur\nDioxide',
          shortLabel: 'SO₂',
          unit: 'ppm',
        );
      default:
        return _GasConfig(
          icon: Icons.bubble_chart_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
          ),
          iconGradient: const LinearGradient(
            colors: [Color(0xFF00695C), Color(0xFF26A69A)],
          ),
          color: const Color(0xFF00796B),
          label: name,
          shortLabel: name,
          unit: 'ppm',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAF5FF),
              Color(0xFFFCFAFF),
              Color(0xFFFFFFFF),
              Color(0xFFF8F5FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: _logsRef.limitToLast(1).onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF7B1FA2)),
                          strokeWidth: 3,
                        ),
                      );
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.snapshot.value == null) {
                      return _noDataWidget();
                    }

                    final Map logs = Map<String, dynamic>.from(
                        snapshot.data!.snapshot.value as Map);
                    final latestLog =
                        Map<String, dynamic>.from(logs.values.first as Map);

                    final sensorType =
                        latestLog['sensorType']?.toString() ?? '';
                    if (!sensorType.toLowerCase().contains('gas')) {
                      return _noDataWidget();
                    }

                    final humidity = latestLog['Humidity'];
                    final temperature = latestLog['Temperature'];
                    final time = latestLog['time']?.toString() ?? '';

                    final List<Map<String, dynamic>> gasReadings = [];
                    for (final key in latestLog.keys) {
                      final val = latestLog[key];
                      if (val is Map) {
                        final m = Map<String, dynamic>.from(val);
                        gasReadings.add({
                          'name': key,
                          'percentage': m['percentage'],
                          'status': m['status'],
                          'value': m['value'],
                        });
                      }
                    }

                    return _buildContent(
                      temperature: temperature,
                      humidity: humidity,
                      time: time,
                      gasReadings: gasReadings,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF9C27B0).withOpacity(0.1),
                  const Color(0xFF7B1FA2).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF7B1FA2),
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
                colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B1FA2).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.cloud_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gas Monitor',
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Live tracking system',
                  style: TextStyle(
                    color: Color(0xFFBA68C8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50)
                          .withOpacity(0.3 + _glowAnimation.value * 0.2),
                      blurRadius: 6,
                      spreadRadius: _glowAnimation.value * 1.5,
                    ),
                  ],
                ),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent({
    required dynamic temperature,
    required dynamic humidity,
    required String time,
    required List<Map<String, dynamic>> gasReadings,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _envCard(
                  label: 'Temperature',
                  value: temperature != null ? '$temperature°C' : '--°C',
                  icon: Icons.thermostat_rounded,
                  accentColor: const Color(0xFFF57C00),
                  bgColor: const Color(0xFFFFF3E0),
                  iconGradient: const LinearGradient(
                    colors: [Color(0xFFE65100), Color(0xFFFF9800)],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _envCard(
                  label: 'Humidity',
                  value: humidity != null ? '$humidity%' : '--%',
                  icon: Icons.water_drop_rounded,
                  accentColor: const Color(0xFF1976D2),
                  bgColor: const Color(0xFFE3F2FD),
                  iconGradient: const LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Gas Levels',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gasReadings.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              return _gasGridCard(gasReadings[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _envCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required LinearGradient iconGradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: iconGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gasGridCard(Map<String, dynamic> gas) {
    final name = gas['name']?.toString() ?? '';
    final percentage = gas['percentage'];
    final status = gas['status']?.toString() ?? '';
    final value = gas['value'];

    final gc = _gasConfig(name);
    final sc = _statusConfig(status);

    double progress = 0.0;
    if (percentage != null) {
      progress = (double.tryParse(percentage.toString()) ?? 0.0) / 100.0;
      progress = progress.clamp(0.0, 1.0);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: gc.gradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: gc.color.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon + Status badge ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: gc.iconGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gc.color.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(gc.icon, color: Colors.white, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: sc.bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sc.icon, color: sc.color, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        sc.label,
                        style: TextStyle(
                          color: sc.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // ── Gas short label ──
            Text(
              gc.shortLabel,
              style: TextStyle(
                color: gc.color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),

            // ── Gas full label ──
            Text(
              gc.label,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),

            const SizedBox(height: 10),

            // ── VALUE (left)  +  PERCENTAGE (right) — same line, same size ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value != null ? '$value' : '--',
                  style: TextStyle(
                    color: gc.color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  gc.unit,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // ── Percentage — same fontSize (22) as value ──
                Text(
                  '${percentage ?? '--'}%',
                  style: TextStyle(
                    color: gc.color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Progress bar ──
            Stack(
              children: [
                Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: gc.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: progress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOut,
                  builder: (_, val, __) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: val,
                    child: Container(
                      height: 7,
                      decoration: BoxDecoration(
                        gradient: gc.iconGradient,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: gc.color.withOpacity(0.4),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _noDataWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF7B1FA2).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 46, color: Color(0xFF7B1FA2)),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Gas Data Available',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Make sure your device is\nonline and transmitting.',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusConfig {
  final Color color, bgColor;
  final IconData icon;
  final String label;
  const _StatusConfig({
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.label,
  });
}

class _GasConfig {
  final IconData icon;
  final LinearGradient gradient, iconGradient;
  final Color color;
  final String label, shortLabel, unit;
  const _GasConfig({
    required this.icon,
    required this.gradient,
    required this.iconGradient,
    required this.color,
    required this.label,
    required this.shortLabel,
    required this.unit,
  });
}