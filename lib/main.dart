import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'data/storage/local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
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
          final storage = LocalStorage();
          storage.init();
          return storage;
        }),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          if (!themeProvider.hasLoaded) {
            themeProvider.load();
          }
          return MaterialApp(
            title: 'Calc For All',
            debugShowCheckedModeBanner: false,
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
