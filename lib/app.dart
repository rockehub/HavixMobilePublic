import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';
import 'core/navigation/app_router.dart';
import 'core/store/storefront_store.dart';
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
        builder: (context, child) => _StorefrontShell(child: child!),
      ),
    );
  }
}

class _StorefrontShell extends StatelessWidget {
  final Widget child;
  const _StorefrontShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StorefrontStore>();

    if (store.isLoading) {
      return _SplashScreen(
        logoUrl: store.cachedLogoUrl,
        storeName: store.cachedStoreName,
      );
    }

    if (store.hasError || store.resolveData == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Não foi possível conectar à loja',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  store.errorMessage ?? 'Verifique sua conexão e tente novamente.',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    final themeProvider = context.read<ThemeProvider>();
                    store.initialize(themeProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return child;
  }
}

class _SplashScreen extends StatelessWidget {
  final String? logoUrl;
  final String? storeName;

  const _SplashScreen({this.logoUrl, this.storeName});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;
    final accent = Theme.of(context).colorScheme.primary;
    final resolvedLogo = logoUrl != null ? AppConfig.resolveMediaUrl(logoUrl!) : null;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Logo or initial avatar
            if (resolvedLogo != null && resolvedLogo.isNotEmpty)
              CachedNetworkImage(
                imageUrl: resolvedLogo,
                width: 96,
                height: 96,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => _LogoFallback(name: storeName, accent: accent),
              )
            else
              _LogoFallback(name: storeName, accent: accent),
            if (storeName != null && storeName!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                storeName!,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const Spacer(),
            // Subtle loader at the bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: accent.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  final String? name;
  final Color accent;
  const _LogoFallback({required this.name, required this.accent});

  @override
  Widget build(BuildContext context) {
    final initial = (name?.isNotEmpty == true) ? name![0].toUpperCase() : 'S';
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800),
      ),
    );
  }
}
