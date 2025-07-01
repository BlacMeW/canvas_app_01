import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'jean_meeus_widget.dart';

class SolarSystemPage extends StatelessWidget {
  const SolarSystemPage({super.key});

  // Map planet names to asset filenames
  static const Map<String, String> planetSymbolAssets = {
    'Mercury': 'assets/planet_symbols/mercury.png',
    'Venus': 'assets/planet_symbols/venus.png',
    'Earth': 'assets/planet_symbols/earth.png',
    'Mars': 'assets/planet_symbols/mars.png',
    'Jupiter': 'assets/planet_symbols/jupiter.png',
    'Saturn': 'assets/planet_symbols/saturn.png',
    'Uranus': 'assets/planet_symbols/uranus.png',
    'Neptune': 'assets/planet_symbols/neptune.png',
    'Sun': 'assets/planet_symbols/sun.png',
  };

  @override
  Widget build(BuildContext context) {
    final GlobalKey<_SolarSystemCanvasPanelState> canvasPanelKey =
        GlobalKey<_SolarSystemCanvasPanelState>();
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: AppBar(
          title: Row(
            children: [
              // Use Sun symbol if available, else fallback to icon
              Image.asset(
                planetSymbolAssets['Sun']!,
                width: 22,
                height: 22,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.public, size: 22),
              ),
              const SizedBox(width: 8),
              const Text(
                'Solar System (Jean Meeus)',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: 0.2),
              ),
              const Spacer(),
              Tooltip(
                message: 'About',
                child: IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('About'),
                        content: const Text(
                          'This interactive visualization shows the solar system using Jean Meeus\' algorithms.\n\n'
                          'You can explore planetary positions, toggle centric overlays, and view planetary data.\n\n'
                          'Drag to pan, scroll to zoom, or use the controls above the canvas.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          centerTitle: false,
          elevation: 1.0,
          backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.98),
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          toolbarHeight: 44,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
          titleSpacing: 8,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
                border: const Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app, size: 18, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  const Text('Pan: Drag  ', style: TextStyle(fontSize: 13)),
                  const Icon(Icons.zoom_in, size: 18, color: Colors.blueGrey),
                  const SizedBox(width: 2),
                  const Text('Zoom: Scroll or buttons  ', style: TextStyle(fontSize: 13)),
                  const Icon(Icons.check_box, size: 18, color: Colors.blueGrey),
                  const SizedBox(width: 2),
                  const Text('Overlays: Toggle checkboxes', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: ResizablePanels(
                leftPanel: JeanMeeusWidgetPanel(
                  onDateChanged: (date) => canvasPanelKey.currentState?.setDate(date),
                ),
                rightPanel: SolarSystemCanvasPanel(key: canvasPanelKey),
              ),
            ),
          ],
        ),
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
  bool _showMercuryCentric = false;
  bool _showVenusCentric = false;
  bool _showMarsCentric = false;
  bool _showJupiterCentric = false;
  bool _showSaturnCentric = false;
  void setShowMarsCentric(bool value) {
    setState(() {
      _showMarsCentric = value;
    });
    _canvasKey.currentState?.setShowMarsCentric(value);
  }

  void setShowJupiterCentric(bool value) {
    setState(() {
      _showJupiterCentric = value;
    });
    _canvasKey.currentState?.setShowJupiterCentric(value);
  }

  void setShowSaturnCentric(bool value) {
    setState(() {
      _showSaturnCentric = value;
    });
    _canvasKey.currentState?.setShowSaturnCentric(value);
  }

  void setShowGeocentric(bool value) {
    setState(() {
      _showGeocentric = value;
    });
    _canvasKey.currentState?.setShowGeocentric(value);
  }

  void setShowVenusCentric(bool value) {
    setState(() {
      _showVenusCentric = value;
    });
    _canvasKey.currentState?.setShowVenusCentric(value);
  }

  void setShowMercuryCentric(bool value) {
    setState(() {
      _showMercuryCentric = value;
    });
    _canvasKey.currentState?.setShowMercuryCentric(value);
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
    final List<_CentricOptionData> centricOptions = [
      _CentricOptionData(
        value: _showGeocentric,
        onChanged: setShowGeocentric,
        label: 'Geocentric',
        color: Colors.greenAccent,
        icon: Icons.public,
        asset: null, // No PNG for geocentric
      ),
      _CentricOptionData(
        value: _showMercuryCentric,
        onChanged: setShowMercuryCentric,
        label: 'Mercury',
        color: Colors.orangeAccent,
        icon: Icons.brightness_low,
        asset: SolarSystemPage.planetSymbolAssets['Mercury'],
      ),
      _CentricOptionData(
        value: _showVenusCentric,
        onChanged: setShowVenusCentric,
        label: 'Venus',
        color: Colors.pinkAccent,
        icon: Icons.brightness_2,
        asset: SolarSystemPage.planetSymbolAssets['Venus'],
      ),
      _CentricOptionData(
        value: _showMarsCentric,
        onChanged: setShowMarsCentric,
        label: 'Mars',
        color: Colors.redAccent,
        icon: Icons.brightness_3,
        asset: SolarSystemPage.planetSymbolAssets['Mars'],
      ),
      _CentricOptionData(
        value: _showJupiterCentric,
        onChanged: setShowJupiterCentric,
        label: 'Jupiter',
        color: Colors.brown,
        icon: Icons.brightness_5,
        asset: SolarSystemPage.planetSymbolAssets['Jupiter'],
      ),
      _CentricOptionData(
        value: _showSaturnCentric,
        onChanged: setShowSaturnCentric,
        label: 'Saturn',
        color: Colors.amber,
        icon: Icons.brightness_6,
        asset: SolarSystemPage.planetSymbolAssets['Saturn'],
      ),
    ];

    return Column(
      children: [
        // Options row
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
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
                ...centricOptions.map(
                  (opt) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (opt.asset != null)
                            Image.asset(
                              opt.asset!,
                              width: 18,
                              height: 18,
                              color: opt.value ? opt.color : Colors.grey,
                              errorBuilder: (context, error, stackTrace) => opt.icon != null
                                  ? Icon(
                                      opt.icon,
                                      size: 18,
                                      color: opt.value ? opt.color : Colors.grey,
                                    )
                                  : const SizedBox.shrink(),
                            )
                          else if (opt.icon != null)
                            Icon(opt.icon, size: 18, color: opt.value ? opt.color : Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            opt.label,
                            style: TextStyle(
                              color: opt.value ? opt.color : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      selected: opt.value,
                      selectedColor: opt.color.withOpacity(0.18),
                      backgroundColor: Colors.grey.withOpacity(0.08),
                      checkmarkColor: opt.color,
                      onSelected: (v) => opt.onChanged(!opt.value),
                      showCheckmark: true,
                    ),
                  ),
                ),
              ],
            ),
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
                  showMercuryCentric: _showMercuryCentric,
                  showVenusCentric: _showVenusCentric,
                  showMarsCentric: _showMarsCentric,
                  showJupiterCentric: _showJupiterCentric,
                  showSaturnCentric: _showSaturnCentric,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Helper class for centric overlay options
/// Data class for centric overlay toggle options in the UI.
class _CentricOptionData {
  final bool value;
  final void Function(bool) onChanged;
  final String label;
  final Color color;
  final IconData? icon;
  final String? asset;

  const _CentricOptionData({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.color,
    this.icon,
    this.asset,
  });

  @override
  String toString() => '_CentricOptionData(label: $label, value: $value)';

  _CentricOptionData copyWith({
    bool? value,
    void Function(bool)? onChanged,
    String? label,
    Color? color,
    IconData? icon,
    String? asset,
  }) {
    return _CentricOptionData(
      value: value ?? this.value,
      onChanged: onChanged ?? this.onChanged,
      label: label ?? this.label,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      asset: asset ?? this.asset,
    );
  }
}

class SolarSystemCanvas extends StatefulWidget {
  final double zoom;
  final bool showGeocentric;
  final bool showMercuryCentric;
  final bool showVenusCentric;
  final bool showMarsCentric;
  final bool showJupiterCentric;
  final bool showSaturnCentric;
  const SolarSystemCanvas({
    super.key,
    this.zoom = 20.0,
    this.showGeocentric = false,
    this.showMercuryCentric = false,
    this.showVenusCentric = false,
    this.showMarsCentric = false,
    this.showJupiterCentric = false,
    this.showSaturnCentric = false,
  });

  @override
  State<SolarSystemCanvas> createState() => _SolarSystemCanvasState();
}

class _SolarSystemCanvasState extends State<SolarSystemCanvas> {
  double _zoom = 20.0;
  bool _showGeocentric = false;
  bool _showMercuryCentric = false;
  bool _showVenusCentric = false;
  void setShowVenusCentric(bool value) {
    setState(() {
      _showVenusCentric = value;
    });
  }

  void setShowMercuryCentric(bool value) {
    setState(() {
      _showMercuryCentric = value;
    });
  }

  bool _showMarsCentric = false;
  bool _showJupiterCentric = false;
  bool _showSaturnCentric = false;
  void setShowMarsCentric(bool value) {
    setState(() {
      _showMarsCentric = value;
    });
  }

  void setShowJupiterCentric(bool value) {
    setState(() {
      _showJupiterCentric = value;
    });
  }

  void setShowSaturnCentric(bool value) {
    setState(() {
      _showSaturnCentric = value;
    });
  }

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
    _showMercuryCentric = widget.showMercuryCentric;
    _showVenusCentric = widget.showVenusCentric;
    _showMarsCentric = widget.showMarsCentric;
    _showJupiterCentric = widget.showJupiterCentric;
    _showSaturnCentric = widget.showSaturnCentric;
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
                      showMercuryCentric: _showMercuryCentric,
                      showVenusCentric: _showVenusCentric,
                      showMarsCentric: _showMarsCentric,
                      showJupiterCentric: _showJupiterCentric,
                      showSaturnCentric: _showSaturnCentric,
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
  static const List<String> planetOrder = [
    'Mercury',
    'Venus',
    'Earth',
    'Mars',
    'Jupiter',
    'Saturn',
    'Uranus',
    'Neptune',
  ];

  final Map<String, double> planetLongitudes;
  final double sunLongitude;
  final Map<String, Offset> planetPositions; // heliocentric positions in AU
  final ThemeData? theme;
  final double zoom;
  final bool showGeocentric;
  final bool showMercuryCentric;
  final bool showVenusCentric;
  final bool showMarsCentric;
  final bool showJupiterCentric;
  final bool showSaturnCentric;
  final Offset panOffset;

  List<Color> get planetColors {
    return [
      theme?.colorScheme.secondary ?? const Color(0xFFB0B0B0), // Mercury
      const Color(0xFFFFC300), // Venus
      theme?.colorScheme.primary ?? const Color(0xFF2196F3), // Earth
      const Color(0xFFE53935), // Mars
      const Color(0xFFB8860B), // Jupiter
      const Color(0xFFBDB76B), // Saturn
      const Color(0xFF00B8D4), // Uranus
      const Color(0xFF3F51B5), // Neptune
    ];
  }

  SolarSystemPainter({
    required this.planetLongitudes,
    required this.sunLongitude,
    required this.planetPositions,
    this.theme,
    this.zoom = 1.0,
    this.showGeocentric = false,
    this.showMercuryCentric = false,
    this.showVenusCentric = false,
    this.showMarsCentric = false,
    this.showJupiterCentric = false,
    this.showSaturnCentric = false,
    this.panOffset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2) + panOffset;
    // Find max AU for scaling
    double maxAU = planetPositions.values.map((p) => p.distance).fold(1.0, math.max);
    double scale = size.shortestSide * 0.45 / maxAU * zoom;

    // Helper to draw centric overlays (Mars, Jupiter, Saturn)
    void drawCentricOverlay({
      required String planetName,
      required bool show,
      required Color color,
    }) {
      if (!show || !planetPositions.containsKey(planetName)) return;
      final Offset centricAU = planetPositions[planetName]!;
      final Offset centricPos = center + Offset(centricAU.dx * scale, centricAU.dy * scale);
      final Offset? neptuneAU = planetPositions['Neptune'];
      if (neptuneAU != null) {
        double centricRadius = (neptuneAU - centricAU).distance * scale;
        final Paint centricCirclePaint = Paint()
          ..color = color.withOpacity(0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawCircle(centricPos, centricRadius, centricCirclePaint);
      }
      final Paint centricLinePaint = Paint()
        ..color = color.withOpacity(0.5)
        ..strokeWidth = 2;
      for (final planet in SolarSystemPainter.planetOrder) {
        if (planet == planetName) continue;
        final Offset? pAU = planetPositions[planet];
        if (pAU == null) continue;
        final Offset pPos = center + Offset(pAU.dx * scale, pAU.dy * scale);
        canvas.drawLine(centricPos, pPos, centricLinePaint);
        double dx = pAU.dx - centricAU.dx;
        double dy = pAU.dy - centricAU.dy;
        double angle = math.atan2(dy, dx) * 180 / math.pi;
        if (angle < 0) angle += 360;
        final angleLabel = TextSpan(
          text: '${angle.toStringAsFixed(1)}°',
          style: TextStyle(
            color: color,
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
        final Offset labelPos =
            centricPos +
            (pPos - centricPos) * 0.6 -
            Offset(anglePainter.width / 2, anglePainter.height / 2);
        anglePainter.paint(canvas, labelPos);
      }
    }

    // Draw centric overlays
    drawCentricOverlay(planetName: 'Mars', show: showMarsCentric, color: Colors.redAccent);
    drawCentricOverlay(planetName: 'Jupiter', show: showJupiterCentric, color: Colors.brown);
    drawCentricOverlay(planetName: 'Saturn', show: showSaturnCentric, color: Colors.amber);

    // Draw orbits (circles for each planet's mean distance)
    final Paint orbitPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (int i = 0; i < SolarSystemPainter.planetOrder.length; i++) {
      double rAU =
          planetPositions[SolarSystemPainter.planetOrder[i]]?.distance ?? (i + 1).toDouble();
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
      for (final planet in SolarSystemPainter.planetOrder) {
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

    // Draw Mercury-centric circle and angles if enabled
    if (showMercuryCentric && planetPositions.containsKey('Mercury')) {
      final Offset mercuryAU = planetPositions['Mercury']!;
      final Offset mercuryPos = center + Offset(mercuryAU.dx * scale, mercuryAU.dy * scale);
      // Mercury-centric circle: radius = distance to Neptune
      final Offset? neptuneAU = planetPositions['Neptune'];
      if (neptuneAU != null) {
        double mercRadius = (neptuneAU - mercuryAU).distance * scale;
        final Paint mercCirclePaint = Paint()
          ..color = Colors.orangeAccent.withOpacity(0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawCircle(mercuryPos, mercRadius, mercCirclePaint);
      }
      // Draw Mercury-centric lines and angles
      final Paint mercLinePaint = Paint()
        ..color = Colors.orangeAccent.withOpacity(0.5)
        ..strokeWidth = 2;
      for (final planet in SolarSystemPainter.planetOrder) {
        if (planet == 'Mercury') continue;
        final Offset? pAU = planetPositions[planet];
        if (pAU == null) continue;
        final Offset pPos = center + Offset(pAU.dx * scale, pAU.dy * scale);
        canvas.drawLine(mercuryPos, pPos, mercLinePaint);
        // Draw angle label
        double dx = pAU.dx - mercuryAU.dx;
        double dy = pAU.dy - mercuryAU.dy;
        double angle = math.atan2(dy, dx) * 180 / math.pi;
        if (angle < 0) angle += 360;
        final angleLabel = TextSpan(
          text: '${angle.toStringAsFixed(1)}°',
          style: TextStyle(
            color: Colors.orangeAccent,
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
        // Place angle label at 60% of the way from Mercury to planet
        final Offset labelPos =
            mercuryPos +
            (pPos - mercuryPos) * 0.6 -
            Offset(anglePainter.width / 2, anglePainter.height / 2);
        anglePainter.paint(canvas, labelPos);
      }
    }

    // Draw Venus-centric circle and angles if enabled
    if (showVenusCentric && planetPositions.containsKey('Venus')) {
      final Offset venusAU = planetPositions['Venus']!;
      final Offset venusPos = center + Offset(venusAU.dx * scale, venusAU.dy * scale);
      // Venus-centric circle: radius = distance to Neptune
      final Offset? neptuneAU = planetPositions['Neptune'];
      if (neptuneAU != null) {
        double venusRadius = (neptuneAU - venusAU).distance * scale;
        final Paint venusCirclePaint = Paint()
          ..color = Colors.pinkAccent.withOpacity(0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawCircle(venusPos, venusRadius, venusCirclePaint);
      }
      // Draw Venus-centric lines and angles
      final Paint venusLinePaint = Paint()
        ..color = Colors.pinkAccent.withOpacity(0.5)
        ..strokeWidth = 2;
      for (final planet in SolarSystemPainter.planetOrder) {
        if (planet == 'Venus') continue;
        final Offset? pAU = planetPositions[planet];
        if (pAU == null) continue;
        final Offset pPos = center + Offset(pAU.dx * scale, pAU.dy * scale);
        canvas.drawLine(venusPos, pPos, venusLinePaint);
        // Draw angle label
        double dx = pAU.dx - venusAU.dx;
        double dy = pAU.dy - venusAU.dy;
        double angle = math.atan2(dy, dx) * 180 / math.pi;
        if (angle < 0) angle += 360;
        final angleLabel = TextSpan(
          text: '${angle.toStringAsFixed(1)}°',
          style: TextStyle(
            color: Colors.pinkAccent,
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
        // Place angle label at 60% of the way from Venus to planet
        final Offset labelPos =
            venusPos +
            (pPos - venusPos) * 0.6 -
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
    // Compute Earth's heliocentric position for geocentric calculation
    final Offset? earthAU = planetPositions['Earth'];
    for (int i = 0; i < SolarSystemPainter.planetOrder.length; i++) {
      String planet = SolarSystemPainter.planetOrder[i];
      final Offset? posAU = planetPositions[planet];
      if (posAU == null) continue;
      final Offset pos = center + Offset(posAU.dx * scale, posAU.dy * scale);
      final Paint planetPaint = Paint()
        ..color = planetColors[i]
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(pos, scale * 0.045, planetPaint);

      // Calculate geocentric position (relative to Earth)
      String geoLabel = '';
      if (earthAU != null && planet != 'Earth') {
        final geoX = (posAU.dx - earthAU.dx).toStringAsFixed(2);
        final geoY = (posAU.dy - earthAU.dy).toStringAsFixed(2);
        geoLabel = '\nGeo: ($geoX, $geoY) AU';
      }

      // Draw planet label with position and geocentric position
      final label = TextSpan(
        text:
            '$planet\n(${posAU.dx.toStringAsFixed(2)}, ${posAU.dy.toStringAsFixed(2)}) AU$geoLabel',
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
        maxLines: 3,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, pos + Offset(-labelPainter.width / 2, scale * 0.06));
    }
  }

  @override
  bool shouldRepaint(covariant SolarSystemPainter oldDelegate) {
    return oldDelegate.planetLongitudes != planetLongitudes ||
        oldDelegate.sunLongitude != sunLongitude ||
        oldDelegate.showGeocentric != showGeocentric ||
        oldDelegate.showMercuryCentric != showMercuryCentric ||
        oldDelegate.showVenusCentric != showVenusCentric ||
        oldDelegate.showMarsCentric != showMarsCentric ||
        oldDelegate.showJupiterCentric != showJupiterCentric ||
        oldDelegate.showSaturnCentric != showSaturnCentric ||
        oldDelegate.zoom != zoom ||
        oldDelegate.panOffset != panOffset;
  }
}
