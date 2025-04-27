import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: themeProvider.themeMode == ThemeMode.light
            ? const Icon(Icons.dark_mode, key: ValueKey('dark'))
            : const Icon(Icons.light_mode, key: ValueKey('light')),
      ),
      onPressed: () {
        themeProvider.toggleTheme();
      },
    );
  }
}
