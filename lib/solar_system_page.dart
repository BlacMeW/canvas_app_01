import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'jean_meeus_widget.dart';

class SolarSystemPage extends StatelessWidget {
  const SolarSystemPage({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<_SolarSystemCanvasPanelState> canvasPanelKey =
        GlobalKey<_SolarSystemCanvasPanelState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Solar System (Jean Meeus)')),
      body: ResizablePanels(
        leftPanel: JeanMeeusWidgetPanel(
          onDateChanged: (date) => canvasPanelKey.currentState?.setDate(date),
        ),
        rightPanel: SolarSystemCanvasPanel(key: canvasPanelKey),
      ),
    );
  }
}

// A widget for resizable horizontal panels (left/right)
class ResizablePanels extends StatefulWidget {
  final Widget leftPanel;
  final Widget rightPanel;
  const ResizablePanels({required this.leftPanel, required this.rightPanel, super.key});

  @override
  State<ResizablePanels> createState() => _ResizablePanelsState();
}

class _ResizablePanelsState extends State<ResizablePanels> {
  double _leftFraction = 0.32; // initial width fraction for left panel
  static const double _minFraction = 0.18;
  static const double _maxFraction = 0.6;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final leftWidth = width * _leftFraction;
        final rightWidth = width - leftWidth - 8;
        return Row(
          children: [
            SizedBox(width: leftWidth, child: widget.leftPanel),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (_) => setState(() => _dragging = true),
              onHorizontalDragEnd: (_) => setState(() => _dragging = false),
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _leftFraction += details.delta.dx / width;
                  _leftFraction = _leftFraction.clamp(_minFraction, _maxFraction);
                });
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Container(
                  width: 8,
                  height: double.infinity,
                  color: _dragging
                      ? Theme.of(context).colorScheme.secondary.withOpacity(0.25)
                      : Colors.transparent,
                  child: Center(
                    child: Container(
                      width: 3,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: rightWidth, child: widget.rightPanel),
          ],
        );
      },
    );
  }
}

// Wrapper for JeanMeeusWidget to allow resizing
class JeanMeeusWidgetPanel extends StatefulWidget {
  final void Function(DateTime)? onDateChanged;
  const JeanMeeusWidgetPanel({super.key, this.onDateChanged});

  @override
  State<JeanMeeusWidgetPanel> createState() => _JeanMeeusWidgetPanelState();
}

class _JeanMeeusWidgetPanelState extends State<JeanMeeusWidgetPanel> {
  final double _widthFraction = 1.0;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth * _widthFraction,
          child: JeanMeeusWidget(onDateChanged: widget.onDateChanged),
        );
      },
    );
  }
}

// Wrapper for SolarSystemCanvas to allow resizing
class SolarSystemCanvasPanel extends StatefulWidget {
  const SolarSystemCanvasPanel({super.key});

  @override
  State<SolarSystemCanvasPanel> createState() => _SolarSystemCanvasPanelState();
}

class _SolarSystemCanvasPanelState extends State<SolarSystemCanvasPanel> {
  bool _showGeocentric = false;

  void setShowGeocentric(bool value) {
    setState(() {
      _showGeocentric = value;
    });
    _canvasKey.currentState?.setShowGeocentric(value);
  }

  double _zoom = 20.0;

  void setZoom(double zoom) {
    setState(() {
      _zoom = zoom.clamp(0.1, 100.0);
    });
    _canvasKey.currentState?.setZoom(_zoom);
  }

  final double _widthFraction = 1.0;
  final GlobalKey<_SolarSystemCanvasState> _canvasKey = GlobalKey<_SolarSystemCanvasState>();

  void setDate(DateTime date) {
    _canvasKey.currentState?.setDate(date);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Options row
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_out),
                tooltip: 'Zoom Out',
                onPressed: () => setZoom(_zoom / 1.2),
              ),
              Text('Zoom: ${_zoom.toStringAsFixed(2)}x'),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                tooltip: 'Zoom In',
                onPressed: () => setZoom(_zoom * 1.2),
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Checkbox(value: _showGeocentric, onChanged: (v) => setShowGeocentric(v ?? false)),
                  const Text('Show Geocentric Circle & Angles'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth * _widthFraction,
                height: constraints.maxHeight,
                child: SolarSystemCanvas(
                  key: _canvasKey,
                  zoom: _zoom,
                  showGeocentric: _showGeocentric,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SolarSystemCanvas extends StatefulWidget {
  final double zoom;
  final bool showGeocentric;
  const SolarSystemCanvas({super.key, this.zoom = 20.0, this.showGeocentric = false});

  @override
  State<SolarSystemCanvas> createState() => _SolarSystemCanvasState();
}

class _SolarSystemCanvasState extends State<SolarSystemCanvas> {
  double _zoom = 20.0;
  bool _showGeocentric = false;

  Offset _panOffset = Offset.zero;
  Offset? _lastDragPos;

  void setShowGeocentric(bool value) {
    setState(() {
      _showGeocentric = value;
    });
  }

  void setZoom(double zoom) {
    setState(() {
      _zoom = zoom.clamp(0.1, 100.0);
    });
  }

  void _resetPan() {
    setState(() {
      _panOffset = Offset.zero;
    });
  }

  // Returns heliocentric (x, y) in AU for each planet (mean longitude, circular orbit)
  Map<String, Offset> getHeliocentricPositions() {
    // Mean distances in AU (approximate, for demo)
    const Map<String, double> meanR = {
      'Mercury': 0.387,
      'Venus': 0.723,
      'Earth': 1.0,
      'Mars': 1.524,
      'Jupiter': 5.203,
      'Saturn': 9.537,
      'Uranus': 19.191,
      'Neptune': 30.07,
    };
    Map<String, Offset> positions = {};
    planetLongitudes.forEach((planet, L) {
      double r = meanR[planet] ?? 1.0;
      double angleRad = L * math.pi / 180.0;
      double x = r * math.cos(angleRad);
      double y = r * math.sin(angleRad);
      positions[planet] = Offset(x, y);
    });
    return positions;
  }

  Map<String, double> planetLongitudes = {};
  double sunLongitude = 0.0;
  DateTime date = DateTime.now();

  void setDate(DateTime newDate) {
    date = newDate;
    _calculateMeeus(date);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateMeeus(date);
    _zoom = widget.zoom;
    _showGeocentric = widget.showGeocentric;
  }

  void _calculateMeeus(DateTime selectedDate) {
    int Y = selectedDate.year;
    int M = selectedDate.month;
    double D =
        selectedDate.day +
        (selectedDate.hour / 24) +
        (selectedDate.minute / 1440) +
        (selectedDate.second / 86400);
    if (M <= 2) {
      Y -= 1;
      M += 12;
    }
    int A = (Y / 100).floor();
    int B = 2 - A + (A / 4).floor();
    double julianDay = (365.25 * (Y + 4716)).floor() + (30.6001 * (M + 1)).floor() + D + B - 1524.5;
    double T = (julianDay - 2451545.0) / 36525.0;
    sunLongitude = 280.46646 + 36000.76983 * T + 0.0003032 * T * T;
    sunLongitude = sunLongitude % 360;
    planetLongitudes = _calculatePlanetPositions(julianDay);
    setState(() {});
  }

  Map<String, double> _calculatePlanetPositions(double jd) {
    double T = (jd - 2451545.0) / 36525.0;
    Map<String, double> L = {};
    L['Mercury'] = (252.250906 + 149472.6746358 * T) % 360;
    L['Venus'] = (181.979801 + 58517.8156760 * T) % 360;
    L['Earth'] = (100.466457 + 35999.3728565 * T) % 360;
    L['Mars'] = (355.433000 + 19140.2993039 * T) % 360;
    L['Jupiter'] = (34.351519 + 3034.9056606 * T) % 360;
    L['Saturn'] = (50.077444 + 1222.1138488 * T) % 360;
    L['Uranus'] = (314.055005 + 428.4669983 * T) % 360;
    L['Neptune'] = (304.348665 + 218.4862002 * T) % 360;
    L.updateAll((k, v) => v < 0 ? v + 360 : v);
    return L;
  }

  @override
  Widget build(BuildContext context) {
    final planetPositions = getHeliocentricPositions();
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  final scroll = event.scrollDelta.dy;
                  setState(() {
                    if (scroll < 0) {
                      _zoom = (_zoom * 1.1).clamp(0.1, 100.0);
                    } else if (scroll > 0) {
                      _zoom = (_zoom / 1.1).clamp(0.1, 100.0);
                    }
                  });
                }
              },
              child: GestureDetector(
                onPanStart: (details) {
                  _lastDragPos = details.localPosition;
                },
                onPanUpdate: (details) {
                  setState(() {
                    if (_lastDragPos != null) {
                      _panOffset += details.localPosition - _lastDragPos!;
                    }
                    _lastDragPos = details.localPosition;
                  });
                },
                onPanEnd: (_) {
                  _lastDragPos = null;
                },
                child: Container(
                  color: Colors.black,
                  child: CustomPaint(
                    size: size,
                    painter: SolarSystemPainter(
                      planetLongitudes: planetLongitudes,
                      sunLongitude: sunLongitude,
                      planetPositions: planetPositions,
                      theme: Theme.of(context),
                      zoom: _zoom,
                      showGeocentric: _showGeocentric,
                      panOffset: _panOffset,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: ElevatedButton.icon(
                onPressed: _resetPan,
                icon: const Icon(Icons.center_focus_strong),
                label: const Text('Recenter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 13),
                  elevation: 0,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SolarSystemPainter extends CustomPainter {
  final Map<String, double> planetLongitudes;
  final double sunLongitude;
  final Map<String, Offset> planetPositions; // heliocentric positions in AU
  final ThemeData? theme;
  final double zoom;
  final bool showGeocentric;
  final Offset panOffset;
  SolarSystemPainter({
    required this.planetLongitudes,
    required this.sunLongitude,
    required this.planetPositions,
    this.theme,
    this.zoom = 1.0,
    this.showGeocentric = false,
    this.panOffset = Offset.zero,
  });

  final List<String> planetOrder = [
    'Mercury',
    'Venus',
    'Earth',
    'Mars',
    'Jupiter',
    'Saturn',
    'Uranus',
    'Neptune',
  ];
  List<Color> get planetColors => [
    theme?.colorScheme.secondary ?? const Color(0xFFB0B0B0), // Mercury
    const Color(0xFFFFC300), // Venus
    theme?.colorScheme.primary ?? const Color(0xFF2196F3), // Earth
    const Color(0xFFE53935), // Mars
    const Color(0xFFB8860B), // Jupiter
    const Color(0xFFBDB76B), // Saturn
    const Color(0xFF00B8D4), // Uranus
    const Color(0xFF3F51B5), // Neptune
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2) + panOffset;
    // Find max AU for scaling
    double maxAU = planetPositions.values.map((p) => p.distance).fold(1.0, math.max);
    double scale = size.shortestSide * 0.45 / maxAU * zoom;

    // Draw orbits (circles for each planet's mean distance)
    final Paint orbitPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (int i = 0; i < planetOrder.length; i++) {
      double rAU = planetPositions[planetOrder[i]]?.distance ?? (i + 1).toDouble();
      double r = rAU * scale;
      canvas.drawCircle(center, r, orbitPaint);
    }

    // Draw geocentric circle and angles if enabled
    if (showGeocentric && planetPositions.containsKey('Earth')) {
      final Offset earthAU = planetPositions['Earth']!;
      final Offset earthPos = center + Offset(earthAU.dx * scale, earthAU.dy * scale);
      // Geocentric circle: radius = distance to Neptune
      final Offset? neptuneAU = planetPositions['Neptune'];
      if (neptuneAU != null) {
        double geoRadius = (neptuneAU - earthAU).distance * scale;
        final Paint geoCirclePaint = Paint()
          ..color = Colors.greenAccent.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawCircle(earthPos, geoRadius, geoCirclePaint);
      }
      // Draw geocentric lines and angles
      final Paint geoLinePaint = Paint()
        ..color = Colors.greenAccent.withOpacity(0.5)
        ..strokeWidth = 2;
      for (final planet in planetOrder) {
        if (planet == 'Earth') continue;
        final Offset? pAU = planetPositions[planet];
        if (pAU == null) continue;
        final Offset pPos = center + Offset(pAU.dx * scale, pAU.dy * scale);
        canvas.drawLine(earthPos, pPos, geoLinePaint);
        // Draw angle label
        double dx = pAU.dx - earthAU.dx;
        double dy = pAU.dy - earthAU.dy;
        double angle = math.atan2(dy, dx) * 180 / math.pi;
        if (angle < 0) angle += 360;
        final angleLabel = TextSpan(
          text: '${angle.toStringAsFixed(1)}°',
          style: TextStyle(
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
            fontSize: scale * 0.035,
            shadows: [Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1))],
          ),
        );
        final anglePainter = TextPainter(
          text: angleLabel,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        anglePainter.layout();
        // Place angle label at 60% of the way from Earth to planet
        final Offset labelPos =
            earthPos +
            (pPos - earthPos) * 0.6 -
            Offset(anglePainter.width / 2, anglePainter.height / 2);
        anglePainter.paint(canvas, labelPos);
      }
    }

    // Draw Sun with glow
    final Paint sunPaint = Paint()
      ..color = Colors.yellow.shade600
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, scale * 0.09, sunPaint);
    final sunLabel = TextSpan(
      text: 'Sun',
      style: TextStyle(
        color: Colors.yellow.shade200,
        fontWeight: FontWeight.bold,
        fontSize: scale * 0.07,
        shadows: [Shadow(blurRadius: 8, color: Colors.yellow.shade700)],
      ),
    );
    final sunPainter = TextPainter(
      text: sunLabel,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    sunPainter.layout();
    sunPainter.paint(canvas, center + Offset(-sunPainter.width / 2, scale * 0.09));

    // Draw planets at heliocentric positions
    for (int i = 0; i < planetOrder.length; i++) {
      String planet = planetOrder[i];
      final Offset? posAU = planetPositions[planet];
      if (posAU == null) continue;
      final Offset pos = center + Offset(posAU.dx * scale, posAU.dy * scale);
      final Paint planetPaint = Paint()
        ..color = planetColors[i]
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(pos, scale * 0.045, planetPaint);

      // Draw planet label with position
      final label = TextSpan(
        text: '$planet\n(${posAU.dx.toStringAsFixed(2)}, ${posAU.dy.toStringAsFixed(2)}) AU',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: scale * 0.045,
          shadows: [Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1))],
        ),
      );
      final labelPainter = TextPainter(
        text: label,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, pos + Offset(-labelPainter.width / 2, scale * 0.06));
    }
  }

  @override
  bool shouldRepaint(covariant SolarSystemPainter oldDelegate) {
    return oldDelegate.planetLongitudes != planetLongitudes ||
        oldDelegate.sunLongitude != sunLongitude;
  }
}
