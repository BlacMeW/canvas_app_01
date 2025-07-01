import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

typedef JeanMeeusDateChanged = void Function(DateTime date);

class JeanMeeusWidget extends StatefulWidget {
  final JeanMeeusDateChanged? onDateChanged;
  const JeanMeeusWidget({super.key, this.onDateChanged});

  @override
  State<JeanMeeusWidget> createState() => _JeanMeeusWidgetState();
}

class _JeanMeeusWidgetState extends State<JeanMeeusWidget> {
  Timer? _timer;
  bool _timerRunning = false;
  String _timerStep = 'Day'; // 'Hour', 'Day', 'Month'
  int _timerDirection = 1; // 1 for forward, -1 for backward

  void _startTimer() {
    if (_timerRunning) return;
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      switch (_timerStep) {
        case 'Hour':
          _stepHour(_timerDirection);
          break;
        case 'Day':
          _stepDate(Duration(days: 1 * _timerDirection));
          break;
        case 'Month':
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

  void _toggleTimer() {
    if (_timerRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final stepOptions = ['Hour', 'Day', 'Month'];
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
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top bar: Only time machine controls
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                            _setDateTime(
                              DateTime(pickedDate.year, pickedDate.month, pickedDate.day),
                            );
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
                        child: DropdownButton<String>(
                          value: _timerStep,
                          items: stepOptions
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
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
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Selected Date: '
                  '${selectedDate.toIso8601String().substring(0, 10)}'
                  ' ${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}',
                ),
                Text('Julian Day: ${julianDay.toStringAsFixed(5)}'),
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.resolveWith<Color?>(
                      (states) => Theme.of(context).colorScheme.secondary.withOpacity(0.08),
                    ),
                    columns: const [
                      DataColumn(label: Text('Planet')),
                      DataColumn(label: Text('x (AU)')),
                      DataColumn(label: Text('y (AU)')),
                      DataColumn(label: Text('Mean Longitude (°)')),
                    ],
                    rows: planetNames.map((planet) {
                      final pos = planetPositions[planet];
                      final lon = planetLongitudes[planet];
                      return DataRow(
                        cells: [
                          DataCell(Text(planet)),
                          DataCell(Text(pos != null ? pos.dx.toStringAsFixed(4) : '-')),
                          DataCell(Text(pos != null ? pos.dy.toStringAsFixed(4) : '-')),
                          DataCell(Text(lon != null ? lon.toStringAsFixed(2) : '-')),
                        ],
                      );
                    }).toList(),
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
                            child: DropdownButton<String>(
                              value: _timerStep,
                              items: stepOptions
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Row(
                                        children: [
                                          Icon(
                                            s == 'Hour'
                                                ? Icons.schedule
                                                : s == 'Day'
                                                ? Icons.calendar_today
                                                : Icons.calendar_view_month,
                                            size: 18,
                                            color: Theme.of(context).colorScheme.secondary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            s,
                                            style: TextStyle(
                                              fontWeight: _timerStep == s
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: _timerStep == s
                                                  ? Theme.of(context).colorScheme.secondary
                                                  : Theme.of(context).textTheme.bodyLarge?.color,
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
                              style: TextStyle(fontSize: 15),
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
            ),
          ),
        ),
      ),
    );
  }
}
