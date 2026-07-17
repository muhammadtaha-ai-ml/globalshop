import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';

class BulbAutomationScreen extends StatefulWidget {
  final String deviceId;
  const BulbAutomationScreen({super.key, required this.deviceId});
  @override
  State<BulbAutomationScreen> createState() => _BulbAutomationScreenState();
}

class _BulbAutomationScreenState extends State<BulbAutomationScreen>
    with TickerProviderStateMixin {
  late final DatabaseReference _relayRef;
  late final Stream<DatabaseEvent> _relayStream;
  late AnimationController _glowCtrl, _rayCtrl, _swingCtrl;
  late Animation<double> _glowAnim, _rayAnim, _swingAnim;
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    _relayRef = FirebaseDatabase.instance
        .ref('devices').child(widget.deviceId).child('relay');
    _relayStream = _relayRef.onValue;

    _glowCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _rayCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 3000))..repeat();
    _swingCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 4000))..repeat(reverse: true);

    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
    _rayAnim = CurvedAnimation(parent: _rayCtrl, curve: Curves.linear);
    _swingAnim = Tween<double>(begin: -0.03, end: 0.03)
        .animate(CurvedAnimation(parent: _swingCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose(); _rayCtrl.dispose(); _swingCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleRelay(int val) async {
    if (_isSwitching) return;
    setState(() => _isSwitching = true);
    HapticFeedback.heavyImpact();
    try {
      await _relayRef.update({'relay1': val == 1 ? 0 : 1});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _isSwitching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: _relayStream,
      builder: (context, snap) {
        int relayVal = 0;
        bool connected = false;
        if (snap.hasData && snap.data!.snapshot.value != null) {
          connected = true;
          final d = snap.data!.snapshot.value;
          if (d is Map) relayVal = int.tryParse(d['relay1']?.toString() ?? '0') ?? 0;
          else if (d is num) relayVal = d.toInt();
        }
        final isOn = relayVal == 1;

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AnimatedBuilder(
          animation: Listenable.merge([_glowAnim, _rayAnim, _swingAnim]),
          builder: (context, _) {
            return Scaffold(
              body: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                      ? (isOn
                          ? [
                              Color.lerp(const Color(0xFF1A1200), const Color(0xFF2A1E00), _glowAnim.value)!,
                              Color.lerp(const Color(0xFF3D2800), const Color(0xFF4A3200), _glowAnim.value)!,
                              const Color(0xFF1A0E00),
                            ]
                          : [
                              const Color(0xFF0D0E16),
                              const Color(0xFF151725),
                              const Color(0xFF0A0B14),
                            ])
                      : (isOn
                          ? [
                              Color.lerp(const Color(0xFFFFF8E1), const Color(0xFFFFF3CC), _glowAnim.value)!,
                              Color.lerp(const Color(0xFFFFF0CC), const Color(0xFFFFF8E1), _glowAnim.value)!,
                              const Color(0xFFF8F9FA),
                            ]
                          : [
                              const Color(0xFFF8F9FA),
                              const Color(0xFFF2F3F7),
                              const Color(0xFFF8F9FA),
                            ]),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildAppBar(isOn, connected),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background radial glow when ON
                            if (isOn) Positioned(
                              top: 40,
                              child: AnimatedOpacity(
                                opacity: isOn ? 1 : 0,
                                duration: const Duration(milliseconds: 600),
                                child: Container(
                                  width: 400,
                                  height: 400,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(colors: [
                                      const Color(0xFFFFB300).withOpacity(0.18 + _glowAnim.value * 0.1),
                                      const Color(0xFFFF8C00).withOpacity(0.07),
                                      Colors.transparent,
                                    ]),
                                  ),
                                ),
                              ),
                            ),

                            // Light rays
                            if (isOn) CustomPaint(
                              size: Size(MediaQuery.of(context).size.width,
                                  MediaQuery.of(context).size.height * 0.65),
                              painter: _RayPainter(_rayAnim.value, _glowAnim.value),
                            ),

                            // The Hanging Bulb (centered)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Transform.rotate(
                                  angle: _swingAnim.value,
                                  alignment: Alignment.topCenter,
                                  child: Column(
                                    children: [
                                      // Wire from top
                                      Container(
                                        width: 3,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: isOn
                                              ? [const Color(0xFFD32F2F), const Color(0xFF8B1A1A)]
                                              : [const Color(0xFF555770), const Color(0xFF33354A)],
                                          ),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      // Full Bulb Custom Paint
                                      GestureDetector(
                                        onTap: () => _toggleRelay(relayVal),
                                        child: CustomPaint(
                                          size: const Size(160, 230),
                                          painter: _RealisticBulbPainter(
                                            isOn: isOn,
                                            glow: _glowAnim.value,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Status text
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 500),
                                  style: TextStyle(
                                    color: isOn ? const Color(0xFFFFD54F) : const Color(0xFF555770),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                  ),
                                  child: Text(isOn ? '●  SWITCHED ON' : '○  SWITCHED OFF'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildControlCard(isOn, relayVal, connected),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAppBar(bool isOn, bool connected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txtColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.07);
    final backBtnColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF0F1F7);
    final backIconColor = isDark ? Colors.white70 : const Color(0xFF4B5563);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.0 : 0.05),
                blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: backBtnColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 17, color: backIconColor),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFB300), Color(0xFFF57C00)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: const Color(0xFFFFB300).withOpacity(0.4),
                    blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Bulb Control', style: TextStyle(
                    color: txtColor, fontSize: 17, fontWeight: FontWeight.w800)),
                Text(widget.deviceId, style: TextStyle(
                    color: subColor, fontSize: 11, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
              ]),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isOn ? const Color(0xFFFFB300).withOpacity(isDark ? 0.2 : 0.12)
                    : (isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFF0F1F7)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isOn ? const Color(0xFFFFB300).withOpacity(0.4)
                        : borderColor),
              ),
              child: Text(isOn ? 'ON' : 'OFF',
                style: TextStyle(
                  color: isOn ? const Color(0xFFFFB300) : subColor,
                  fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlCard(bool isOn, int relayVal, bool connected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txtColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor = isDark ? Colors.white54 : const Color(0xFF8A8D9E);
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark
        ? (isOn ? const Color(0xFFFFB300).withOpacity(0.2) : Colors.white.withOpacity(0.07))
        : (isOn ? const Color(0xFFFFB300).withOpacity(0.25) : Colors.black.withOpacity(0.06));
    final dividerColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFEEEFF5);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
            blurRadius: 30, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Device Status', style: TextStyle(
                      color: subColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: connected ? const Color(0xFF4CAF50) : Colors.redAccent,
                        boxShadow: [BoxShadow(
                          color: (connected ? const Color(0xFF4CAF50) : Colors.redAccent)
                              .withOpacity(0.6),
                          blurRadius: 6, spreadRadius: 1)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(connected ? 'Connected' : 'Connecting…',
                        style: TextStyle(color: txtColor,
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ]),
                ]),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isOn
                        ? const Color(0xFFFFB300).withOpacity(isDark ? 0.15 : 0.1)
                        : (isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFF0F1F7)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isOn ? const Color(0xFFFFB300).withOpacity(0.35)
                            : borderColor),
                  ),
                  child: Text(isOn ? 'ON' : 'OFF',
                    style: TextStyle(
                      color: isOn ? const Color(0xFFFFB300) : subColor,
                      fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: dividerColor),
            const SizedBox(height: 20),
            _isSwitching
                ? SizedBox(height: 58, child: Center(
                    child: SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(
                          isOn ? const Color(0xFFFFB300) : const Color(0xFF42A5F5))))))
                : GestureDetector(
                    onTap: () => _toggleRelay(relayVal),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: double.infinity, height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isOn
                              ? [const Color(0xFFFFB300), const Color(0xFFF57C00)]
                              : [const Color(0xFF42A5F5), const Color(0xFF1565C0)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(
                          color: (isOn ? const Color(0xFFFFB300)
                              : const Color(0xFF1E88E5)).withOpacity(0.45),
                          blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(isOn ? Icons.power_settings_new_rounded : Icons.lightbulb_rounded,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(isOn ? 'TURN BULB OFF' : 'TURN BULB ON',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                      ]),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ─── Light Rays Painter ───────────────────────────────────────────────────────
class _RayPainter extends CustomPainter {
  final double progress, glow;
  _RayPainter(this.progress, this.glow);

  @override
  void paint(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final cy = s.height * 0.32;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5;

    const rayCount = 12;
    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 2 * math.pi + progress * 2 * math.pi;
      final startR = 90.0;
      final endR = 90 + 60 + math.sin(progress * math.pi * 2 + i) * 20;
      final opacity = (0.05 + glow * 0.08) * (i % 2 == 0 ? 1.0 : 0.5);
      paint.color = const Color(0xFFFFD54F).withOpacity(opacity.clamp(0.0, 1.0));

      canvas.drawLine(
        Offset(cx + startR * math.cos(angle), cy + startR * math.sin(angle)),
        Offset(cx + endR * math.cos(angle), cy + endR * math.sin(angle)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RayPainter old) => true;
}

// ─── Realistic Bulb Painter ───────────────────────────────────────────────────
class _RealisticBulbPainter extends CustomPainter {
  final bool isOn;
  final double glow;
  _RealisticBulbPainter({required this.isOn, required this.glow});

  @override
  void paint(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    // ── Socket (top brown cylinder with ridges) ─────────────────
    // Socket body
    final socketTop = 0.0;
    final socketH = s.height * 0.30;
    final socketW = s.width * 0.42;
    final socketRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(cx - socketW, socketTop, socketW * 2, socketH),
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
      bottomLeft: const Radius.circular(4),
      bottomRight: const Radius.circular(4),
    );

    paint.shader = LinearGradient(
      colors: isOn
          ? [const Color(0xFF8B4513), const Color(0xFF6B3410), const Color(0xFF5A2D0C)]
          : [const Color(0xFF4A4040), const Color(0xFF3A3030), const Color(0xFF2E2525)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromLTWH(cx - socketW, socketTop, socketW * 2, socketH));
    canvas.drawRRect(socketRect, paint);
    paint.shader = null;

    // Socket ridges (horizontal lines)
    final ridgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.butt;
    const ridgeCount = 5;
    for (int i = 1; i <= ridgeCount; i++) {
      final ry = socketTop + (socketH / (ridgeCount + 1)) * i;
      ridgePaint.color = Colors.black.withOpacity(0.25);
      canvas.drawLine(Offset(cx - socketW + 2, ry), Offset(cx + socketW - 2, ry), ridgePaint);
      ridgePaint.color = Colors.white.withOpacity(0.08);
      canvas.drawLine(Offset(cx - socketW + 2, ry + 1.5), Offset(cx + socketW - 2, ry + 1.5), ridgePaint);
    }

    // Socket bottom rim
    final rimH = 12.0;
    paint.color = isOn ? const Color(0xFF4A2000) : const Color(0xFF222020);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - socketW - 4, socketTop + socketH - rimH, socketW * 2 + 8, rimH),
        const Radius.circular(3)),
      paint);

    // ── Transition neck (between socket and globe) ───────────────
    final neckTopY = socketTop + socketH;
    final neckBotY = neckTopY + s.height * 0.08;
    final neckTopW = socketW - 2;
    final neckBotW = s.width * 0.36;
    final neckPath = Path()
      ..moveTo(cx - neckTopW, neckTopY)
      ..lineTo(cx + neckTopW, neckTopY)
      ..quadraticBezierTo(cx + neckBotW + 6, neckTopY + s.height * 0.04, cx + neckBotW, neckBotY)
      ..lineTo(cx - neckBotW, neckBotY)
      ..quadraticBezierTo(cx - neckBotW - 6, neckTopY + s.height * 0.04, cx - neckTopW, neckTopY)
      ..close();

    paint.shader = LinearGradient(
      colors: isOn
          ? [const Color(0xFF7A3B10), const Color(0xFF5A2A08), const Color(0xFF7A3B10)]
          : [const Color(0xFF3A3535), const Color(0xFF2A2525), const Color(0xFF3A3535)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromLTWH(cx - socketW, neckTopY, socketW * 2, s.height * 0.1));
    canvas.drawPath(neckPath, paint);
    paint.shader = null;

    // ── Globe (realistic bulb shape) ─────────────────────────────
    final globeTop = neckBotY;
    final globeR = s.width * 0.44;
    final globeCy = globeTop + globeR * 0.98;

    // Outer glow (when ON)
    if (isOn) {
      final glowOpacity = 0.3 + glow * 0.25;
      for (double i = 0; i < 3; i++) {
        paint.color = const Color(0xFFFFD54F).withOpacity(glowOpacity / (i + 1));
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 15 + i * 10);
        canvas.drawCircle(Offset(cx, globeCy), globeR + i * 8, paint);
      }
      paint.maskFilter = null;
    }

    // Globe body fill
    if (isOn) {
      paint.shader = RadialGradient(
        center: const Alignment(-0.15, -0.2),
        colors: [
          Color.lerp(const Color(0xFFFFF9C4), const Color(0xFFFFFDE7), glow)!,
          Color.lerp(const Color(0xFFFFE57F), const Color(0xFFFFD54F), glow)!,
          const Color(0xFFFFB300),
          const Color(0xFFF57C00),
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, globeCy), radius: globeR));
    } else {
      paint.shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        colors: [
          const Color(0xFF4A4C60),
          const Color(0xFF2E3040),
          const Color(0xFF1E1F2E),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, globeCy), radius: globeR));
    }
    canvas.drawCircle(Offset(cx, globeCy), globeR, paint);
    paint.shader = null;

    // Glass highlight (top-left specular)
    paint.color = Colors.white.withOpacity(isOn ? 0.35 + glow * 0.12 : 0.12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - globeR * 0.28, globeCy - globeR * 0.32),
        width: globeR * 0.42, height: globeR * 0.58),
      paint);

    // Small secondary shine
    paint.color = Colors.white.withOpacity(isOn ? 0.20 : 0.07);
    canvas.drawCircle(Offset(cx + globeR * 0.25, globeCy - globeR * 0.42), globeR * 0.1, paint);

    // Filament detail (inside globe when ON)
    if (isOn) {
      final filPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFF59D).withOpacity(0.7 + glow * 0.3);
      // Zigzag filament
      final filPath = Path();
      final double fx = cx;
      final double fy = globeCy;
      filPath.moveTo(fx, fy - 18);
      filPath.relativeCubicTo(-8, 8, 8, 16, 0, 24);
      filPath.relativeCubicTo(-8, 8, 8, 12, 0, 18);
      canvas.drawPath(filPath, filPaint);
    }

    // Globe bottom flat edge (neck connection)
    final bottomClipPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, globeCy), radius: globeR));

    // Subtle edge shadow at bottom of globe
    paint.color = Colors.black.withOpacity(0.35);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, globeCy), radius: globeR - 4),
      math.pi * 0.25, math.pi * 0.5, false,
      paint..style = PaintingStyle.stroke..strokeWidth = 8);
    paint.maskFilter = null;
    paint.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(_RealisticBulbPainter old) =>
      old.isOn != isOn || old.glow != glow;
}
