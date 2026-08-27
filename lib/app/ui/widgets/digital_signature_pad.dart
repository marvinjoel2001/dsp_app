import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class DigitalSignaturePad extends StatefulWidget {
  final Function(String svgString) onSignatureCaptured;
  final VoidCallback onClear;

  const DigitalSignaturePad({
    super.key,
    required this.onSignatureCaptured,
    required this.onClear,
  });

  @override
  State<DigitalSignaturePad> createState() => DigitalSignaturePadState();
}

class DigitalSignaturePadState extends State<DigitalSignaturePad> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
    widget.onClear();
  }

  bool get hasSignature => _strokes.isNotEmpty;

  String exportSvg({double width = 340, double height = 160}) {
    if (_strokes.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${width.toInt()} ${height.toInt()}" width="${width.toInt()}" height="${height.toInt()}">');
    buffer.write('<rect width="100%" height="100%" fill="none"/>');

    for (final stroke in _strokes) {
      if (stroke.length < 2) continue;
      buffer.write('<path d="M ${stroke.first.dx.toStringAsFixed(1)} ${stroke.first.dy.toStringAsFixed(1)} ');
      for (int i = 1; i < stroke.length; i++) {
        buffer.write('L ${stroke[i].dx.toStringAsFixed(1)} ${stroke[i].dy.toStringAsFixed(1)} ');
      }
      buffer.write('" stroke="#0F172A" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>');
    }

    buffer.write('</svg>');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.draw_outlined, size: 16, color: AppColors.primaryDark),
                SizedBox(width: 6),
                Text(
                  'Firma en el recuadro blanco',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            if (hasSignature)
              TextButton.icon(
                onPressed: clear,
                icon: const Icon(Icons.refresh, size: 14, color: AppColors.error),
                label: const Text('Borrar Firma', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.error)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Área de dibujo interactiva
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasSignature ? AppColors.primary : const Color(0xFFCBD5E1),
              width: hasSignature ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                // Línea guía de firma
                Positioned(
                  bottom: 36,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 1,
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 20,
                  child: Text(
                    'Firma digital del solicitante (C.I.)',
                    style: TextStyle(fontSize: 10, color: const Color(0xFF94A3B8).withValues(alpha: 0.8)),
                  ),
                ),

                // Canvas de dibujo de firma
                GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _currentStroke = [details.localPosition];
                      _strokes.add(_currentStroke);
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _currentStroke.add(details.localPosition);
                    });
                  },
                  onPanEnd: (_) {
                    final svg = exportSvg();
                    widget.onSignatureCaptured(svg);
                  },
                  child: CustomPaint(
                    painter: _SignaturePainter(strokes: _strokes),
                    size: Size.infinite,
                  ),
                ),

                if (!hasSignature)
                  const IgnorePointer(
                    child: Center(
                      child: Text(
                        'Dibuja tu firma con tu dedo aquí',
                        style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _SignaturePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.8
      ..isAntiAlias = true;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
