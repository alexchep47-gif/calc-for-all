import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

/// Écran des réglages
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réglages'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          // Thème
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Thème'),
            subtitle: Text(themeProvider.isOled
                ? 'OLED noir'
                : _themeLabel(themeProvider.themeMode)),
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
                          title: const Text('Système'),
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
            subtitle:
                const Text('Fond noir pour les écrans OLED et la batterie'),
            value: themeProvider.isOled,
            onChanged: (value) => themeProvider.setOled(value),
          ),
          const Divider(),
          // À propos
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos'),
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
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Calc For All est une calculatrice hors ligne, légère et complète.\n'
              'Fonctionnalités : calculatrice scientifique, tracé de courbes, nombres complexes.',
              style: TextStyle(color: Colors.grey),
            ),
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
        return 'Système';
    }
  }
}
