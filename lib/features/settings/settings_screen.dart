import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Reglages')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            subtitle: Text(
              themeProvider.isOled
                  ? 'OLED noir'
                  : _themeLabel(themeProvider.themeMode),
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('Clair'),
                          leading: const Icon(Icons.light_mode),
                          onTap: () {
                            themeProvider.setThemeMode(ThemeMode.light);
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          title: const Text('Sombre'),
                          leading: const Icon(Icons.dark_mode),
                          onTap: () {
                            themeProvider.setThemeMode(ThemeMode.dark);
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          title: const Text('Systeme'),
                          leading: const Icon(Icons.settings_suggest),
                          onTap: () {
                            themeProvider.setThemeMode(ThemeMode.system);
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.contrast_rounded),
            title: const Text('Mode OLED'),
            subtitle: const Text('Fond noir pour ecrans OLED et batterie'),
            value: themeProvider.isOled,
            onChanged: (value) => themeProvider.setOled(value),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.format_size),
            title: const Text('Taille de la police'),
            subtitle: Text('${(themeProvider.fontScale * 100).round()} %'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: themeProvider.fontScale,
              min: 0.85,
              max: 1.35,
              divisions: 10,
              label: '${(themeProvider.fontScale * 100).round()} %',
              onChanged: (v) => themeProvider.setFontScale(v),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('A propos'),
            subtitle:
                Text('${AppConstants.appName} v${AppConstants.appVersion}'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion: AppConstants.appVersion,
                applicationLegalese: '© 2026 — Calc For All',
                children: [
                  const SizedBox(height: 16),
                  Text(AppConstants.appDescription),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.system:
        return 'Systeme';
    }
  }
}
