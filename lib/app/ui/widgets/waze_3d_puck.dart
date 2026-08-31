import 'package:flutter/material.dart';

class Waze3DPuck extends StatefulWidget {
  final double heading;
  final bool is3D;
  final String vehicleType;

  const Waze3DPuck({
    super.key,
    required this.heading,
    this.is3D = true,
    this.vehicleType = 'MOTORCYCLE',
  });

  @override
  State<Waze3DPuck> createState() => _Waze3DPuckState();
}

class _Waze3DPuckState extends State<Waze3DPuck> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Sombra de suelo / Halo difuso en perspectiva
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0284C7).withValues(alpha: 0.28), // Sky Blue Aura
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Anillo interior translúcido
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.9),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),

              // 3. Flecha 3D Waze Chevron (Cian Eléctrico con borde blanco brillante)
              CustomPaint(
                size: const Size(36, 36),
                painter: _WazeChevronPainter(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WazeChevronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    // Forma de flecha 3D estilo Waze
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, 0); // Punta superior
    path.lineTo(w * 0.95, h * 0.9); // Esquina inferior derecha
    path.lineTo(w * 0.5, h * 0.65); // Centro hendido
    path.lineTo(w * 0.05, h * 0.9); // Esquina inferior izquierda
    path.close();

    // Degradado Cian a Azul Eléctrico
    final rect = Rect.fromLTWH(0, 0, w, h);
    const gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF38BDF8), // Cyan brillante
        Color(0xFF0284C7), // Azul Waze
      ],
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    // Sombra interna/profundidad 3D en la mitad derecha
    final rightHalfPath = Path();
    rightHalfPath.moveTo(w * 0.5, 0);
    rightHalfPath.lineTo(w * 0.95, h * 0.9);
    rightHalfPath.lineTo(w * 0.5, h * 0.65);
    rightHalfPath.close();

    final shadePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(rightHalfPath, shadePaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
