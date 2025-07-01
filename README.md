


# Solar System with Jean Meeus

An interactive Flutter app for visualizing the solar system and exploring astronomical calculations using Jean Meeus' algorithms. Designed for education, research, and curiosity, this app combines trigonometry, planetary motion, and beautiful UI/UX.

## ✨ Features

- **Jean Meeus Astronomical Calculator**
  - Compute Julian Day, Sun and planet mean longitudes, and heliocentric positions.
  - Fully interactive time machine: step by hour, day, month, year; pick any date/time; jump to now; play/pause; reverse direction.
  - Planetary data in a responsive, sortable table.

- **Solar System Visualization**
  - Animated orbits, Sun, and planets with real-time positions and labels.
  - Zoom and pan (mouse wheel, drag, recenter button).
  - Toggle geocentric overlays: lines, circle, and angle labels from Earth's perspective.
  - Multi-planet centric: select any planet(s) as the center for geocentric overlays.
  - Modular, resizable panels for calculations and visualization.

- **Trigonometry & Ellipse Canvas**
  - Explore trigonometric circles and ellipses interactively.

- **Modern UI/UX**
  - Compact, visually appealing, and dark theme ready.
  - Responsive layout with smooth controls and tooltips.

## 🚀 Getting Started

1. **Requirements:**
   - Flutter SDK (latest stable)
   - Dart SDK

2. **Run the App:**
   ```bash
   flutter pub get
   flutter run
   ```
   Supports Linux desktop, web, and Android.

3. **Usage:**
   - Use the left panel for astronomical calculations and time controls.
   - The right panel visualizes the solar system with interactive controls.
   - All features are intuitive and tooltips are provided.

## 📁 Project Structure

- `lib/main.dart` — App entry point and theming
- `lib/jean_meeus_widget.dart` — Astronomical calculations and time machine
- `lib/solar_system_page.dart` — Solar system visualization and layout
- `lib/trig_circle_page.dart` — Trigonometry/ellipse canvas
- `test/` — Widget and integration tests

## 📝 Credits
- Astronomical algorithms adapted from Jean Meeus, "Astronomical Algorithms"
- Flutter and Dart open source community

## 📄 License
MIT License

2. **Run the App:**
   ```bash
   flutter pub get
   flutter run
   ```
   The app supports desktop (Linux), web, and Android platforms.

3. **Usage:**
   - Use the left panel to explore astronomical calculations and control the time machine.
   - The right panel visualizes the solar system, with interactive zoom, pan, and geocentric overlays.
   - All controls are intuitive and tooltips are provided for guidance.

## Project Structure

- `lib/main.dart` — App entry point and theming
- `lib/jean_meeus_widget.dart` — Astronomical calculations and time machine widget
- `lib/solar_system_page.dart` — Solar system visualization and resizable layout
- `lib/trig_circle_page.dart` — Trigonometry/ellipse canvas
- `test/` — Widget and integration tests

## Credits
- Astronomical algorithms adapted from Jean Meeus, "Astronomical Algorithms"
- Flutter and Dart open source community

## License
This project is open source and available under the MIT License.
