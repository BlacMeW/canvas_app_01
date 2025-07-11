import 'dart:math' as math;

import 'package:flutter/material.dart';

class TrigCirclePage extends StatefulWidget {
  const TrigCirclePage({super.key});

  @override
  State<TrigCirclePage> createState() => _TrigCirclePageState();
}

class _TrigCirclePageState extends State<TrigCirclePage> {
  double angle = 0.0;
  Offset? dragPosition;
  double ellipseA = 240;
  double ellipseB = 180;

  void _updateAngle(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final vector = localPosition - center;
    setState(() {
      angle = vector.direction;
    });
  }

  void _onTapDown(TapDownDetails details, Size size) {
    _updateAngle(details.localPosition, size);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interactive Trigonometry & Ellipse')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight - 140);
          return SingleChildScrollView(
            child: Column(
              children: [
                // JeanMeeusWidget should be imported and used in main.dart
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Angle:  {(angle * 180 / 3.141592653589793).toStringAsFixed(2)}°'),
                          Text('sin(θ):  {math.sin(angle).toStringAsFixed(3)}'),
                          Text('cos(θ):  {math.cos(angle).toStringAsFixed(3)}'),
                          const SizedBox(height: 8),
                          Text(
                            'Ellipse (a =  {ellipseA.toStringAsFixed(2)}, b =  {ellipseB.toStringAsFixed(2)})',
                          ),
                          Text('Ellipse X:  {(ellipseA * math.cos(angle)).toStringAsFixed(2)}'),
                          Text('Ellipse Y:  {(ellipseB * math.sin(angle)).toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: size.height * 0.9,
                      width: size.width * 0.7,
                      child: GestureDetector(
                        onPanStart: (details) {
                          _updateAngle(
                            details.localPosition,
                            Size(size.width * 0.7, size.height * 0.9),
                          );
                        },
                        onPanUpdate: (details) {
                          _updateAngle(
                            details.localPosition,
                            Size(size.width * 0.7, size.height * 0.9),
                          );
                        },
                        onTapDown: (details) {
                          _onTapDown(details, Size(size.width * 0.7, size.height * 0.9));
                        },
                        behavior: HitTestBehavior.opaque,
                        child: CustomPaint(
                          size: Size(size.width * 0.7, size.height * 0.9),
                          painter: TrigCirclePainter(
                            angle: angle,
                            ellipseA: ellipseA,
                            ellipseB: ellipseB,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TrigCirclePainter extends CustomPainter {
  final double angle;
  final double ellipseA;
  final double ellipseB;
  TrigCirclePainter({required this.angle, this.ellipseA = 120, this.ellipseB = 80});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.49;
    final circlePaint = Paint()
      ..color = Colors.blue.shade100
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;
    final pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, circlePaint);

    final ellipsePaint = Paint()
      ..color = Colors.teal.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: ellipseA * 2, height: ellipseB * 2),
      ellipsePaint,
    );

    canvas.drawLine(center + Offset(-radius, 0), center + Offset(radius, 0), axisPaint);
    canvas.drawLine(center + Offset(0, -radius), center + Offset(0, radius), axisPaint);

    final point = center + Offset(radius * math.cos(angle), radius * math.sin(angle));
    final radiusPaint = Paint()
      ..color = Colors.deepPurple
      ..strokeWidth = 2;
    canvas.drawLine(center, point, radiusPaint);

    canvas.drawCircle(point, 8, pointPaint);

    final ellipsePoint = center + Offset(ellipseA * math.cos(angle), ellipseB * math.sin(angle));
    final ellipseRadiusPaint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 2;
    canvas.drawLine(center, ellipsePoint, ellipseRadiusPaint);

    canvas.drawCircle(ellipsePoint, 8, Paint()..color = Colors.teal);

    final sinPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final cosPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(point, Offset(point.dx, center.dy), sinPaint);
    canvas.drawLine(center, Offset(point.dx, center.dy), cosPaint);

    final arcPaint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final arcRect = Rect.fromCircle(center: center, radius: radius * 0.3);
    canvas.drawArc(arcRect, 0, angle, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant TrigCirclePainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.ellipseA != ellipseA ||
        oldDelegate.ellipseB != ellipseB;
  }
}
