import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/collage_screen.dart';
import 'services/collage_manager.dart';
import 'services/purchase_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFFFFFFF);
    const surface = Color(0xFFF6F6F6);
    const surfaceAlt = Color(0xFFEDEDED);
    const primary = Color(0xFF121212);
    const secondary = Color(0xFFD6D6D6);

    final scheme = const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.black87,
      surface: surface,
      onSurface: Colors.black87,
    );

    TextTheme bolden(TextTheme t) => TextTheme(
          displayLarge: t.displayLarge?.copyWith(fontWeight: FontWeight.w600),
          displayMedium: t.displayMedium?.copyWith(fontWeight: FontWeight.w600),
          displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.w600),
          headlineLarge: t.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
          headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
          headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          bodyLarge: t.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          bodyMedium: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          bodySmall: t.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          labelMedium: t.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          labelSmall: t.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PurchaseService()..initialize(),
        ),
        ChangeNotifierProxyProvider<PurchaseService, CollageManager>(
          create: (_) => CollageManager(),
          update: (_, purchaseService, collageManager) {
            final CollageManager manager = collageManager ?? CollageManager();
            manager.setPremium(purchaseService.hasActiveSubscription);
            return manager;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Custom Collage',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          colorScheme: scheme,
          scaffoldBackgroundColor: background,
          canvasColor: surface,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: primary,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            iconTheme: IconThemeData(color: primary),
            actionsIconTheme: IconThemeData(color: primary),
          ),
          dialogTheme: DialogThemeData(backgroundColor: surface),
          cardColor: surfaceAlt,
          iconTheme: const IconThemeData(color: primary),
          textTheme: bolden(
            ThemeData.light().textTheme.apply(bodyColor: primary, displayColor: primary),
          ),
          primaryTextTheme: bolden(
            ThemeData.light().primaryTextTheme.apply(bodyColor: primary, displayColor: primary),
          ),
          useMaterial3: true,
        ),
        home: const CollageScreen(),
      ),
    );
  }
}
