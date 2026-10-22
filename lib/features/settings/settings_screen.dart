import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/l10n/locale_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final isFr = localeProvider.isFrench;

    return Scaffold(
      appBar: AppBar(title: Text(isFr ? 'Réglages' : 'Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(isFr ? 'Langue' : 'Language'),
            subtitle: Text(isFr ? 'Français' : 'English'),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('Français'),
                          leading: const Text('🇫🇷', style: TextStyle(fontSize: 22)),
                          trailing: isFr
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            localeProvider.setLocale(const Locale('fr'));
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          title: const Text('English'),
                          leading: const Text('🇬🇧', style: TextStyle(fontSize: 22)),
                          trailing: !isFr
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            localeProvider.setLocale(const Locale('en'));
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text(isFr ? 'Thème' : 'Theme'),
            subtitle: Text(
              themeProvider.isOled
                  ? (isFr ? 'OLED noir' : 'OLED black')
                  : _themeLabel(themeProvider.themeMode, isFr),
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
                          title: Text(isFr ? 'Clair' : 'Light'),
                          leading: const Icon(Icons.light_mode),
                          onTap: () {
                            themeProvider.setThemeMode(ThemeMode.light);
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          title: Text(isFr ? 'Sombre' : 'Dark'),
                          leading: const Icon(Icons.dark_mode),
                          onTap: () {
                            themeProvider.setThemeMode(ThemeMode.dark);
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          title: Text(isFr ? 'Système' : 'System'),
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
            title: Text(isFr ? 'Mode OLED' : 'OLED mode'),
            subtitle: Text(isFr
                ? 'Fond noir pour écrans OLED et batterie'
                : 'Black background for OLED screens'),
            value: themeProvider.isOled,
            onChanged: (value) => themeProvider.setOled(value),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.format_size),
            title: Text(isFr ? 'Taille de la police' : 'Font size'),
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
            title: Text(isFr ? 'À propos' : 'About'),
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

  String _themeLabel(ThemeMode mode, bool isFr) {
    switch (mode) {
      case ThemeMode.light:
        return isFr ? 'Clair' : 'Light';
      case ThemeMode.dark:
        return isFr ? 'Sombre' : 'Dark';
      case ThemeMode.system:
        return isFr ? 'Système' : 'System';
    }
  }
}
