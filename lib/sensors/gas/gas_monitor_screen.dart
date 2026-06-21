import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';

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
    with TickerProviderStateMixin {
  late final DatabaseReference _logsRef;
  late final Stream<DatabaseEvent> _logsStream;
  late AnimationController _glowController;
  late AnimationController _ringController;
  late Animation<double> _glowAnimation;
  late Animation<double> _ringAnimation;
  List<Map<String, dynamic>> _allLogs = [];
  String? _selectedGasKey; // For dropdown chart selection

  @override
  void initState() {
    super.initState();
    _logsRef = FirebaseDatabase.instance
        .ref('devices')
        .child(widget.deviceId)
        .child('logs');
    _logsStream = _logsRef.limitToLast(30).onValue;

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _ringAnimation = CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _ringController.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0B10) : const Color(0xFFF8F9FA),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0F1016),
                    const Color(0xFF141622),
                    const Color(0xFF1F1B2C),
                  ]
                : [
                    const Color(0xFFFAF5FF),
                    const Color(0xFFFCFAFF),
                    const Color(0xFFFFFFFF),
                    const Color(0xFFF8F5FF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: _logsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Lottie.asset(
                          'assets/animations/loader.json',
                          width: 160,
                          height: 160,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const CircularProgressIndicator(
                              color: Color(0xFF7B1FA2),
                            );
                          },
                        ),
                      );
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.snapshot.value == null) {
                      return _noDataWidget();
                    }

                    final Map logs = Map<String, dynamic>.from(
                        snapshot.data!.snapshot.value as Map);
                    final sortedKeys = logs.keys.toList()..sort();
                    final latestLog =
                        Map<String, dynamic>.from(logs[sortedKeys.last] as Map);

                    final sensorType = latestLog['sensorType']?.toString().toLowerCase() ?? 'gas';
                    if (!sensorType.contains('gas')) {
                      return _noDataWidget();
                    }

                    // Safely extract temperature and humidity whether they are maps or primitives
                    dynamic rawTemp = latestLog['Temperature'] ?? latestLog['temperature'];
                    dynamic temperature = (rawTemp is Map) ? rawTemp['value'] : rawTemp;

                    dynamic rawHum = latestLog['Humidity'] ?? latestLog['humidity'];
                    dynamic humidity = (rawHum is Map) ? rawHum['value'] : rawHum;

                    final time = latestLog['time']?.toString() ?? '';

                    final List<Map<String, dynamic>> gasReadings = [];
                    final excludedKeys = ['temperature', 'humidity', 'time', 'sensortype', 'deviceid'];

                    for (final key in latestLog.keys) {
                      if (excludedKeys.contains(key.toLowerCase())) continue;

                      final val = latestLog[key];
                      if (val is Map) {
                        final m = Map<String, dynamic>.from(val);
                        // Ensure this map is actually a gas reading structure
                        if (m.containsKey('value') || m.containsKey('percentage') || m.containsKey('status')) {
                          gasReadings.add({
                            'name': key,
                            'percentage': m['percentage'],
                            'status': m['status'],
                            'value': m['value'],
                          });
                        }
                      }
                    }

                    // Alarm Soundscape: Trigger siren/alert sound if any gas status is danger or critical!
                    final bool hasDanger = gasReadings.any((g) {
                      final status = g['status']?.toString().toLowerCase() ?? '';
                      return status.contains('danger') || status.contains('critical');
                    });

                    if (hasDanger) {
                      Future.microtask(() {
                        SystemSound.play(SystemSoundType.alert);
                        HapticFeedback.vibrate();
                      });
                    }

                    // Parse all logs for history chart
                    _allLogs = sortedKeys.map((k) {
                      return Map<String, dynamic>.from(logs[k] as Map);
                    }).toList();

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
                  const Color(0xFF9C27B0).withOpacity(isDark ? 0.2 : 0.1),
                  const Color(0xFF7B1FA2).withOpacity(isDark ? 0.2 : 0.1),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gas Monitor',
                  style: TextStyle(
                    color: textThemeColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
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
                  value: temperature != null 
                      ? '${double.tryParse(temperature.toString())?.toStringAsFixed(1) ?? temperature}°C' 
                      : '--°C',
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
                  value: humidity != null 
                      ? '${double.tryParse(humidity.toString())?.toStringAsFixed(1) ?? humidity}%' 
                      : '--%',
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
              Text(
                'Gas Levels',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1A1A1A),
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

          const SizedBox(height: 24),

          // ── Historical Spline Chart with Gas Selector Dropdown ──
          if (_allLogs.length > 1 && gasReadings.isNotEmpty)
            _buildGasChartSection(gasReadings),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2030) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(isDark ? 0.25 : 0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(isDark ? 0.02 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => iconGradient.createShader(bounds),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white, // fallback
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gasGridCard(Map<String, dynamic> gas) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

    return AnimatedBuilder(
      animation: _ringAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2030) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: gc.color.withOpacity(isDark 
                  ? (0.25 + _ringAnimation.value * 0.25) 
                  : (0.45 + _ringAnimation.value * 0.15)), 
              width: 1.8,
            ),
            boxShadow: [
              // Glowing neon ring shadow – pulses with _ringAnimation
              BoxShadow(
                color: gc.color.withOpacity(isDark 
                    ? (0.15 + _ringAnimation.value * 0.25) 
                    : (0.32 + _ringAnimation.value * 0.2)),
                blurRadius: 20 + _ringAnimation.value * 12,
                spreadRadius: 1 + _ringAnimation.value * 3,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: gc.color.withOpacity(isDark ? 0.04 : 0.015),
                blurRadius: 8,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Concentric glowing ring in the card backdrop
            Positioned(
              right: -15,
              top: -15,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: gc.color.withOpacity(0.03),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: -35,
              top: -35,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: gc.color.withOpacity(0.015),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Icon + Status badge ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: gc.iconGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: gc.color.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(gc.icon, color: Colors.white, size: 20),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: sc.bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: sc.color.withOpacity(0.15), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(sc.icon, color: sc.color, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              sc.label.toUpperCase(),
                              style: TextStyle(
                                color: sc.color,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 1),

                  // ── Gas full label ──
                  Text(
                    gc.label,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF2D2D2D),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // ── VALUE (left)  +  PERCENTAGE (right) ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value != null ? '$value' : '--',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        gc.unit,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      // ── Percentage ──
                      Text(
                        '${percentage ?? '--'}%',
                        style: TextStyle(
                          color: gc.color,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ── Progress bar ──
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: gc.color.withOpacity(0.08),
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
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: gc.iconGradient,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: gc.color.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1.5),
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
          ],
        ),
      ),
    );
  }

  Widget _buildGasChartSection(List<Map<String, dynamic>> gasReadings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Initialize if null
    _selectedGasKey ??= gasReadings.first['name']?.toString();
    
    // Fallback if not found in list
    if (!gasReadings.any((g) => g['name']?.toString() == _selectedGasKey)) {
      _selectedGasKey = gasReadings.first['name']?.toString();
    }
    
    final gc = _gasConfig(_selectedGasKey ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selector Header Card
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2030) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2E324A) : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Gas to view History:',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGasKey,
                  icon: Icon(Icons.arrow_drop_down_rounded, color: gc.color, size: 28),
                  dropdownColor: isDark ? const Color(0xFF1E2030) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  style: TextStyle(
                    color: gc.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedGasKey = newValue;
                      });
                    }
                  },
                  items: gasReadings.map<DropdownMenuItem<String>>((gas) {
                    final String gasKey = gas['name']?.toString() ?? '';
                    final config = _gasConfig(gasKey);
                    return DropdownMenuItem<String>(
                      value: gasKey,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(config.icon, color: config.color, size: 18),
                          const SizedBox(width: 8),
                          Text(config.shortLabel),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        
        // The spline chart
        _buildHistoryChart(_selectedGasKey ?? ''),
      ],
    );
  }

  Widget _buildHistoryChart(String gasKey) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gc = _gasConfig(gasKey);

    // Extract percentage history from logs
    final List<FlSpot> spots = [];
    for (int i = 0; i < _allLogs.length; i++) {
      final log = _allLogs[i];
      final gasData = log[gasKey];
      double? pct;
      if (gasData is Map) {
        pct = double.tryParse(gasData['percentage']?.toString() ?? '');
      }
      if (pct != null) {
        spots.add(FlSpot(i.toDouble(), pct.clamp(0, 100)));
      }
    }

    if (spots.length < 2) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2030) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: gc.color.withOpacity(isDark ? 0.25 : 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gc.color.withOpacity(isDark ? 0.06 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: gc.iconGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${gc.shortLabel} History',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: gc.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${spots.length} readings',
                  style: TextStyle(
                    color: gc.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.12),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}%',
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => isDark ? const Color(0xFF2C2F45) : Colors.white,
                    getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                      '${s.y.toStringAsFixed(1)}%',
                      TextStyle(
                        color: gc.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    )).toList(),
                  ),
                  handleBuiltInTouches: true,
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: gc.color,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: spots.length <= 10,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 4,
                        color: gc.color,
                        strokeColor: isDark ? const Color(0xFF1E2030) : Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          gc.color.withOpacity(isDark ? 0.25 : 0.18),
                          gc.color.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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