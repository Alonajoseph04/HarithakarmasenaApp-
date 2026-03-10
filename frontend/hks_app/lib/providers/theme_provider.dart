import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool('dark_mode') ?? false;
    _mode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggle() async {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _mode == ThemeMode.dark);
    notifyListeners();
  }
}

/// Global singleton — created in main.dart and shared everywhere.
final globalTheme = ThemeProvider();

/// A small icon button placed in AppBars / landing screen to toggle dark/light.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});
  @override
  Widget build(BuildContext context) {
    // Rebuilt by ThemeProvider
    return ListenableBuilder(
      listenable: globalTheme,
      builder: (ctx, _) => Tooltip(
        message: globalTheme.isDark ? 'Light Mode' : 'Dark Mode',
        child: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              globalTheme.isDark ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
              key: ValueKey(globalTheme.isDark),
              color: Colors.white,
            ),
          ),
          onPressed: globalTheme.toggle,
        ),
      ),
    );
  }
}
