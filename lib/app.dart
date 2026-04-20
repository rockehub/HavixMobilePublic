import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/theme_provider.dart';

class HavixApp extends StatelessWidget {
  const HavixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => MaterialApp.router(
        title: AppConfig.appName,
        theme: themeProvider.themeData,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'BR'),
      ),
    );
  }
}
