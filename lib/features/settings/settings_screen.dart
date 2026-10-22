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
      appBar: AppBar(
        title: Text(isFr ? 'Paramètres' : 'Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(isFr ? 'Langue' : 'Language'),
            subtitle: Text(isFr ? 'Français' : 'English'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'fr', label: Text('FR')),
                ButtonSegment(value: 'en', label: Text('EN')),
              ],
              selected: {localeProvider.locale.languageCode},
              onSelectionChanged: (s) {
                localeProvider.setLocale(Locale(s.first));
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(isFr ? 'Thème' : 'Theme'),
            subtitle: Text(_themeLabel(themeProvider.themeMode, isFr)),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final mode in ThemeMode.values)
                        RadioListTile<ThemeMode>(
                          title: Text(_themeLabel(mode, isFr)),
                          value: mode,
                          groupValue: themeProvider.themeMode,
                          onChanged: (v) {
                            if (v != null) themeProvider.setThemeMode(v);
                            Navigator.pop(ctx);
                          },
                        ),
                      SwitchListTile(
                        title: Text(isFr ? 'OLED noir' : 'OLED black'),
                        value: themeProvider.isOled,
                        onChanged: (v) {
                          themeProvider.setOled(v);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: Text(isFr ? 'Taille du texte' : 'Font size'),
            subtitle: Slider(
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
              // Dialogue personnalisé — sans "Powered by Flutter"
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(AppConstants.appName),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Version ${AppConstants.appVersion}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      Text(AppConstants.appDescription),
                      const SizedBox(height: 16),
                      const Text(
                        '© 2026 — Calc For All',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isFr
                            ? 'Application éducative hors ligne.\nAucune publicité.'
                            : 'Offline educational app.\nNo ads.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(isFr ? 'Fermer' : 'Close'),
                    ),
                  ],
                ),
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
