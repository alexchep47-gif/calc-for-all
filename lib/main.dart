import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/l10n/locale_provider.dart';
import 'data/storage/local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    setUrlStrategy(HashUrlStrategy());
  }

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(const CalcForAllApp());
}

class CalcForAllApp extends StatelessWidget {
  const CalcForAllApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) {
          final locale = LocaleProvider();
          locale.load();
          return locale;
        }),
        ChangeNotifierProvider(create: (_) {
          final storage = LocalStorage();
          storage.init();
          return storage;
        }),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          if (!themeProvider.hasLoaded) {
            themeProvider.load();
          }
          return MaterialApp(
            title: 'Calc For All',
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('fr'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.lightTheme,
            darkTheme:
                themeProvider.isOled ? AppTheme.oledTheme : AppTheme.darkTheme,
            themeMode:
                themeProvider.isOled ? ThemeMode.dark : themeProvider.themeMode,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(themeProvider.fontScale),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            initialRoute: AppRoutes.onboarding,
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}
