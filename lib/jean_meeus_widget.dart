import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

enum TimerStep { hour, day, month }

typedef JeanMeeusDateChanged = void Function(DateTime date);

class JeanMeeusWidget extends StatefulWidget {
  final JeanMeeusDateChanged? onDateChanged;
  const JeanMeeusWidget({super.key, this.onDateChanged});

  @override
  State<JeanMeeusWidget> createState() => _JeanMeeusWidgetState();
}

class _JeanMeeusWidgetState extends State<JeanMeeusWidget> {
  /// Returns the color and text style for a planet row in the data table.
  MapEntry<Color?, TextStyle?> getPlanetRowStyle(String planet) {
    // Style map for planet rows
    final styleMap = <String, MapEntry<Color?, TextStyle?>>{
      'Mercury': MapEntry(
        Colors.grey.shade900.withOpacity(0.04),
        TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold),
      ),
      'Venus': MapEntry(
        Colors.yellow.shade100.withOpacity(0.10),
        TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold),
      ),
      'Earth': MapEntry(
        Colors.blue.shade100.withOpacity(0.10),
        TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
      ),
      'Mars': MapEntry(
        Colors.red.shade100.withOpacity(0.10),
        TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
      ),
      'Jupiter': MapEntry(
        Colors.brown.shade100.withOpacity(0.10),
        TextStyle(color: Colors.brown.shade700, fontWeight: FontWeight.bold),
      ),
      'Saturn': MapEntry(
        Colors.amber.shade100.withOpacity(0.10),
        TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold),
      ),
      'Uranus': MapEntry(
        Colors.cyan.shade100.withOpacity(0.10),
        TextStyle(color: Colors.cyan.shade700, fontWeight: FontWeight.bold),
      ),
      'Neptune': MapEntry(
        Colors.indigo.shade100.withOpacity(0.10),
        TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold),
      ),
    };
    return styleMap[planet] ?? const MapEntry(null, null);
  }

  // Generic method to get planet-centric positions or longitudes
  Map<String, Offset> getCentricPositions(String center) {
    return getPlanetCentricPositions(center);
  }

  Map<String, double> getCentricLongitudes(String center) {
    return getPlanetCentricLongitudes(center);
  }

  // Returns planet-centric (x, y) in AU for each planet, with given center
  Map<String, Offset> getPlanetCentricPositions(String center) {
    final helio = getHeliocentricPositions();
    final centerPos = helio[center];
    if (centerPos == null) return {};
    Map<String, Offset> centric = {};
    helio.forEach((planet, pos) {
      if (planet == center) {
        centric[planet] = Offset(0, 0);
      } else {
        centric[planet] = Offset(pos.dx - centerPos.dx, pos.dy - centerPos.dy);
      }
    });
    return centric;
  }

  // Returns planet-centric longitude (degrees) for each planet, with given center
  Map<String, double> getPlanetCentricLongitudes(String center) {
    final centric = getPlanetCentricPositions(center);
    Map<String, double> longitudes = {};
    centric.forEach((planet, pos) {
      if (planet == center) {
        longitudes[planet] = 0.0;
      } else {
        double angle = math.atan2(pos.dy, pos.dx) * 180.0 / math.pi;
        if (angle < 0) angle += 360.0;
        longitudes[planet] = angle;
      }
    });
    return longitudes;
  }

  // Returns geocentric longitude (degrees) for each planet (Earth at 0,0)
  Map<String, double> getGeocentricLongitudes() {
    final geo = getGeocentricPositions();
    Map<String, double> longitudes = {};
    geo.forEach((planet, pos) {
      if (planet == 'Earth') {
        longitudes[planet] = 0.0;
      } else {
        double angle = math.atan2(pos.dy, pos.dx) * 180.0 / math.pi;
        if (angle < 0) angle += 360.0;
        longitudes[planet] = angle;
      }
    });
    return longitudes;
  }

  // Returns geocentric (x, y) in AU for each planet (Earth at 0,0)
  Map<String, Offset> getGeocentricPositions() {
    final helio = getHeliocentricPositions();
    final earth = getEarthHeliocentricPosition();
    if (earth == null) return {};
    Map<String, Offset> geo = {};
    helio.forEach((planet, pos) {
      if (planet == 'Earth') {
        geo[planet] = Offset(0, 0);
      } else {
        geo[planet] = Offset(pos.dx - earth.dx, pos.dy - earth.dy);
      }
    });
    return geo;
  }

  Timer? _timer;
  bool _timerRunning = false;
  TimerStep _timerStep = TimerStep.day;
  int _timerDirection = 1; // 1 for forward, -1 for backward

  void _startTimer() {
    if (_timerRunning) return;
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      switch (_timerStep) {
        case TimerStep.hour:
          _stepHour(_timerDirection);
          break;
        case TimerStep.day:
          _stepDate(Duration(days: 1 * _timerDirection));
          break;
        case TimerStep.month:
          _stepMonth(1 * _timerDirection);
          break;
      }
    });
    setState(() {
      _timerRunning = true;
    });
  }

  void _pauseTimer() {
    if (!_timerRunning) return;
    _timer?.cancel();
    setState(() {
      _timerRunning = false;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _timerRunning = false;
      // Optionally reset to initial date or keep current
    });
  }

  // Removed unused _toggleTimer method

  void _stepHour(int hours) {
    setState(() {
      selectedDate = selectedDate.add(Duration(hours: hours));
    });
    _calculateMeeus();
    widget.onDateChanged?.call(selectedDate);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Set the selected date to a specific DateTime (with time)
  void _setDateTime(DateTime dateTime) {
    setState(() {
      selectedDate = dateTime;
    });
    _calculateMeeus();
    widget.onDateChanged?.call(selectedDate);
  }

  // Set the selected date to now (current date and time)
  void _setNow() {
    _setDateTime(DateTime.now());
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

  // Returns (x, y) in AU for Earth's heliocentric position (ecliptic plane, mean longitude)
  Offset? getEarthHeliocentricPosition() {
    // Use mean longitude and assume circular orbit (for demo)
    double L = planetLongitudes['Earth'] ?? 0.0; // degrees
    double r = 1.0; // AU (mean distance)
    double angleRad = L * 3.141592653589793 / 180.0;
    double x = r * math.cos(angleRad);
    double y = r * math.sin(angleRad);
    return Offset(x, y);
  }

  // Time machine control: step days/months/years
  void _stepDate(Duration delta) {
    setState(() {
      selectedDate = selectedDate.add(delta);
    });
    _calculateMeeus();
    widget.onDateChanged?.call(selectedDate);
  }

  void _stepMonth(int months) {
    setState(() {
      int year = selectedDate.year;
      int month = selectedDate.month + months;
      while (month > 12) {
        year++;
        month -= 12;
      }
      while (month < 1) {
        year--;
        month += 12;
      }
      int day = selectedDate.day;
      int lastDay = DateTime(year, month + 1, 0).day;
      if (day > lastDay) day = lastDay;
      selectedDate = DateTime(year, month, day);
    });
    _calculateMeeus();
    widget.onDateChanged?.call(selectedDate);
  }

  void _stepYear(int years) {
    setState(() {
      int year = selectedDate.year + years;
      int month = selectedDate.month;
      int day = selectedDate.day;
      int lastDay = DateTime(year, month + 1, 0).day;
      if (day > lastDay) day = lastDay;
      selectedDate = DateTime(year, month, day);
    });
    _calculateMeeus();
    widget.onDateChanged?.call(selectedDate);
  }

  DateTime selectedDate = DateTime.now();
  double julianDay = 0.0;
  double sunMeanLongitude = 0.0;
  Map<String, double> planetLongitudes = {};

  @override
  void initState() {
    super.initState();
    _calculateMeeus();
  }

  void _calculateMeeus() {
    // Julian Day calculation (Meeus, simplified, valid for 1900-2099)
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
    julianDay = (365.25 * (Y + 4716)).floor() + (30.6001 * (M + 1)).floor() + D + B - 1524.5;

    // Sun's mean longitude (degrees, Meeus Ch. 25, eq. 25.2)
    double T = (julianDay - 2451545.0) / 36525.0;
    sunMeanLongitude = 280.46646 + 36000.76983 * T + 0.0003032 * T * T;
    sunMeanLongitude = sunMeanLongitude % 360;
    planetLongitudes = _calculatePlanetPositions(julianDay);
    setState(() {});
  }

  // Very simplified mean longitude calculation for major planets (degrees)
  Map<String, double> _calculatePlanetPositions(double jd) {
    // Source: Meeus, Astronomical Algorithms, Ch. 31 (approximate formulae)
    // These are not precise, but good for demonstration.
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
    // Normalize to 0-360
    L.updateAll((k, v) => v < 0 ? v + 360 : v);
    return L;
  }

  // _pickDate removed: replaced by Set Timer (date+time picker)

  String _timerStepLabel(TimerStep step) {
    switch (step) {
      case TimerStep.hour:
        return 'Hour';
      case TimerStep.day:
        return 'Day';
      case TimerStep.month:
        return 'Month';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Centric data for each planet
    final mercuryCentricPositions = getCentricPositions('Mercury');
    final mercuryCentricLongitudes = getCentricLongitudes('Mercury');
    final venusCentricPositions = getCentricPositions('Venus');
    final venusCentricLongitudes = getCentricLongitudes('Venus');
    final marsCentricPositions = getCentricPositions('Mars');
    final marsCentricLongitudes = getCentricLongitudes('Mars');
    final jupiterCentricPositions = getCentricPositions('Jupiter');
    final jupiterCentricLongitudes = getCentricLongitudes('Jupiter');
    final saturnCentricPositions = getCentricPositions('Saturn');
    final saturnCentricLongitudes = getCentricLongitudes('Saturn');
    final stepOptions = TimerStep.values;
    final earthPos = getEarthHeliocentricPosition();
    final planetPositions = getHeliocentricPositions();
    final planetNames = [
      'Mercury',
      'Venus',
      'Earth',
      'Mars',
      'Jupiter',
      'Saturn',
      'Uranus',
      'Neptune',
    ];
    final geocentricPositions = getGeocentricPositions();
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                final controls = [
                  IconButton(
                    tooltip: 'Now',
                    icon: const Icon(Icons.access_time),
                    onPressed: _setNow,
                  ),
                  IconButton(
                    tooltip: 'Pick Date/Time',
                    icon: const Icon(Icons.event),
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2099),
                      );
                      if (pickedDate != null) {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDate),
                        );
                        if (pickedTime != null) {
                          final dt = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                          _setDateTime(dt);
                        } else {
                          _setDateTime(DateTime(pickedDate.year, pickedDate.month, pickedDate.day));
                        }
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'Back 1 day',
                    icon: const Icon(Icons.arrow_left),
                    onPressed: () => _stepDate(const Duration(days: -1)),
                  ),
                  IconButton(
                    tooltip: 'Forward 1 day',
                    icon: const Icon(Icons.arrow_right),
                    onPressed: () => _stepDate(const Duration(days: 1)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 1.2,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<TimerStep>(
                        value: _timerStep,
                        items: stepOptions
                            .map((s) => DropdownMenuItem(value: s, child: Text(_timerStepLabel(s))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _timerStep = val);
                        },
                        style: TextStyle(fontSize: 14),
                        dropdownColor: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _timerRunning ? 'Pause Timer' : 'Start Timer',
                    icon: Icon(_timerRunning ? Icons.pause : Icons.play_arrow),
                    color: _timerRunning ? Colors.amber : Colors.green,
                    onPressed: _timerRunning ? _pauseTimer : _startTimer,
                  ),
                  IconButton(
                    tooltip: 'Stop Timer',
                    icon: const Icon(Icons.stop),
                    color: _timerRunning ? Colors.red : Colors.grey,
                    onPressed: _timerRunning ? _stopTimer : null,
                  ),
                  IconButton(
                    tooltip: 'Reverse Timer Direction',
                    icon: Icon(Icons.swap_horiz),
                    color: _timerDirection == 1 ? Colors.green : Colors.red,
                    onPressed: () {
                      setState(() {
                        _timerDirection *= -1;
                      });
                    },
                  ),
                ];
                final geocentricLongitudes = getGeocentricLongitudes();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Responsive time machine controls
                    if (isNarrow)
                      Wrap(
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: controls,
                      )
                    else
                      Row(crossAxisAlignment: CrossAxisAlignment.center, children: controls),
                    const SizedBox(height: 12),
                    Text(
                      'Selected Date: '
                      '${selectedDate.toIso8601String().substring(0, 10)}'
                      ' ${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}',
                    ),
                    Text('Julian Day: \t${julianDay.toStringAsFixed(5)}'),
                    Text("Sun's Mean Longitude: ${sunMeanLongitude.toStringAsFixed(5)}°"),
                    if (earthPos != null)
                      Text(
                        'Earth heliocentric (mean, AU): x = '
                        '${earthPos.dx.toStringAsFixed(4)}, y = ${earthPos.dy.toStringAsFixed(4)}',
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'Planet Data (Mean, AU & Longitude):',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // Table for planet data
                    SizedBox(
                      height: 260,
                      child: Card(
                        elevation: 2,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Scrollbar(
                          thumbVisibility: true,
                          controller: ScrollController(),
                          notificationPredicate: (notif) => notif.metrics.axis == Axis.horizontal,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Scrollbar(
                              thumbVisibility: true,
                              controller: ScrollController(),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.resolveWith<Color?>(
                                    (states) =>
                                        Theme.of(context).colorScheme.secondary.withOpacity(0.13),
                                  ),
                                  dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                                    (states) => states.contains(WidgetState.selected)
                                        ? Theme.of(context).colorScheme.primary.withOpacity(0.10)
                                        : Colors.transparent,
                                  ),
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        'Planet',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(label: Text('Helio x (AU)')),
                                    DataColumn(label: Text('Helio y (AU)')),
                                    DataColumn(label: Text('Geo x (AU)')),
                                    DataColumn(label: Text('Geo y (AU)')),
                                    DataColumn(label: Text('Geo Long (°)')),
                                    DataColumn(label: Text('Merc x (AU)')),
                                    DataColumn(label: Text('Merc y (AU)')),
                                    DataColumn(label: Text('Merc Long (°)')),
                                    DataColumn(label: Text('Venus x (AU)')),
                                    DataColumn(label: Text('Venus y (AU)')),
                                    DataColumn(label: Text('Venus Long (°)')),
                                    DataColumn(label: Text('Mars x (AU)')),
                                    DataColumn(label: Text('Mars y (AU)')),
                                    DataColumn(label: Text('Mars Long (°)')),
                                    DataColumn(label: Text('Jupiter x (AU)')),
                                    DataColumn(label: Text('Jupiter y (AU)')),
                                    DataColumn(label: Text('Jupiter Long (°)')),
                                    DataColumn(label: Text('Saturn x (AU)')),
                                    DataColumn(label: Text('Saturn y (AU)')),
                                    DataColumn(label: Text('Saturn Long (°)')),
                                    DataColumn(label: Text('Mean Longitude (°)')),
                                  ],
                                  rows: planetNames.map((planet) {
                                    final pos = planetPositions[planet];
                                    final geo = geocentricPositions[planet];
                                    final geoLon = geocentricLongitudes[planet];
                                    final merc = mercuryCentricPositions[planet];
                                    final mercLon = mercuryCentricLongitudes[planet];
                                    final venus = venusCentricPositions[planet];
                                    final venusLon = venusCentricLongitudes[planet];
                                    final mars = marsCentricPositions[planet];
                                    final marsLon = marsCentricLongitudes[planet];
                                    final jup = jupiterCentricPositions[planet];
                                    final jupLon = jupiterCentricLongitudes[planet];
                                    final sat = saturnCentricPositions[planet];
                                    final satLon = saturnCentricLongitudes[planet];
                                    final lon = planetLongitudes[planet];
                                    final styleEntry = getPlanetRowStyle(planet);
                                    final rowColor = styleEntry.key;
                                    final planetStyle = styleEntry.value;
                                    return DataRow(
                                      color: WidgetStateProperty.resolveWith<Color?>(
                                        (states) => rowColor,
                                      ),
                                      cells: [
                                        DataCell(Text(planet, style: planetStyle)),
                                        DataCell(
                                          Text(
                                            pos != null ? pos.dx.toStringAsFixed(4) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            pos != null ? pos.dy.toStringAsFixed(4) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            geo != null ? geo.dx.toStringAsFixed(4) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            geo != null ? geo.dy.toStringAsFixed(4) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            geoLon != null ? geoLon.toStringAsFixed(2) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            merc != null ? merc.dx.toStringAsFixed(4) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            merc != null ? merc.dy.toStringAsFixed(4) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            mercLon != null ? mercLon.toStringAsFixed(2) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            venus != null ? venus.dx.toStringAsFixed(4) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            venus != null ? venus.dy.toStringAsFixed(4) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            venusLon != null ? venusLon.toStringAsFixed(2) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            mars != null ? mars.dx.toStringAsFixed(4) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            mars != null ? mars.dy.toStringAsFixed(4) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            marsLon != null ? marsLon.toStringAsFixed(2) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            jup != null ? jup.dx.toStringAsFixed(4) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            jup != null ? jup.dy.toStringAsFixed(4) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            jupLon != null ? jupLon.toStringAsFixed(2) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            sat != null ? sat.dx.toStringAsFixed(4) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            sat != null ? sat.dy.toStringAsFixed(4) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            satLon != null ? satLon.toStringAsFixed(2) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            lon != null ? lon.toStringAsFixed(2) : '-',
                                            style: planetStyle,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Meeus formulas: Julian Day, Sun Mean Longitude'),
                    const SizedBox(height: 16),
                    // Time machine controls at the bottom (split into two rows)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              tooltip: 'Back 1 year',
                              icon: const Icon(Icons.fast_rewind),
                              onPressed: () => _stepYear(-1),
                            ),
                            IconButton(
                              tooltip: 'Back 1 month',
                              icon: const Icon(Icons.skip_previous),
                              onPressed: () => _stepMonth(-1),
                            ),
                            IconButton(
                              tooltip: 'Back 1 day',
                              icon: const Icon(Icons.arrow_left),
                              onPressed: () => _stepDate(const Duration(days: -1)),
                            ),
                            IconButton(
                              tooltip: 'Forward 1 day',
                              icon: const Icon(Icons.arrow_right),
                              onPressed: () => _stepDate(const Duration(days: 1)),
                            ),
                            IconButton(
                              tooltip: 'Forward 1 month',
                              icon: const Icon(Icons.skip_next),
                              onPressed: () => _stepMonth(1),
                            ),
                            IconButton(
                              tooltip: 'Forward 1 year',
                              icon: const Icon(Icons.fast_forward),
                              onPressed: () => _stepYear(1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.secondary,
                                  width: 1.2,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<TimerStep>(
                                  value: _timerStep,
                                  items: stepOptions
                                      .map(
                                        (s) => DropdownMenuItem<TimerStep>(
                                          value: s,
                                          child: Row(
                                            children: [
                                              Icon(
                                                s == TimerStep.hour
                                                    ? Icons.schedule
                                                    : s == TimerStep.day
                                                    ? Icons.calendar_today
                                                    : Icons.calendar_view_month,
                                                size: 18,
                                                color: Theme.of(context).colorScheme.secondary,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _timerStepLabel(s),
                                                style: TextStyle(
                                                  fontWeight: _timerStep == s
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  color: _timerStep == s
                                                      ? Theme.of(context).colorScheme.secondary
                                                      : Theme.of(
                                                          context,
                                                        ).textTheme.bodyLarge?.color,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _timerStep = val);
                                  },
                                  style: TextStyle(fontSize: 14),
                                  dropdownColor: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Start Timer',
                              icon: const Icon(Icons.play_arrow),
                              color: !_timerRunning ? Colors.green : Colors.grey,
                              onPressed: !_timerRunning ? _startTimer : null,
                            ),
                            IconButton(
                              tooltip: 'Pause Timer',
                              icon: const Icon(Icons.pause),
                              color: _timerRunning ? Colors.amber : Colors.grey,
                              onPressed: _timerRunning ? _pauseTimer : null,
                            ),
                            IconButton(
                              tooltip: 'Stop Timer',
                              icon: const Icon(Icons.stop),
                              color: _timerRunning ? Colors.red : Colors.grey,
                              onPressed: _timerRunning ? _stopTimer : null,
                            ),
                            IconButton(
                              tooltip: 'Reverse Timer Direction',
                              icon: Icon(Icons.swap_horiz),
                              color: _timerDirection == 1 ? Colors.green : Colors.red,
                              onPressed: () {
                                setState(() {
                                  _timerDirection *= -1;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
