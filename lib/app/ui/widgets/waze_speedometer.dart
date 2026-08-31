import 'package:flutter/material.dart';

class WazeSpeedometer extends StatelessWidget {
  final double speedKmh;

  const WazeSpeedometer({super.key, required this.speedKmh});

  @override
  Widget build(BuildContext context) {
    final speedInt = speedKmh.round();

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Slate 800 Waze Dark Dial
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF475569), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anillo perimétrico decorativo de velocímetro
          CustomPaint(
            size: const Size(58, 58),
            painter: _SpeedometerDialPainter(speed: speedInt),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$speedInt',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                'km/h',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedometerDialPainter extends CustomPainter {
  final int speed;
  _SpeedometerDialPainter({required this.speed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final basePaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final activePaint = Paint()
      ..color = const Color(0xFF38BDF8) // Cyan Waze
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    canvas.drawCircle(center, radius, basePaint);

    // Progreso angular según velocidad (hasta 80 km/h)
    final sweepAngle = (speed / 80.0).clamp(0.0, 1.0) * 3.14159 * 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159 * 0.75,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeedometerDialPainter oldDelegate) => oldDelegate.speed != speed;
}
