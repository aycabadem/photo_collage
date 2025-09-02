import 'package:flutter/material.dart';
import 'screens/collage_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // App-wide color palette (updated)
    const primary = Color(0xFF727D73); // #727D73
    const secondary = Color(0xFFAAB99A); // #AAB99A
    const tertiary = Color(0xFFD0DDD0); // #D0DDD0
    const surface = Color(0xFFF0F0D7); // #F0F0D7

    final scheme = const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.black,
      tertiary: tertiary,
      onTertiary: Colors.black,
      surface: surface,
      onSurface: Colors.black87,
      background: surface,
      onBackground: Colors.black87,
    );

    TextTheme _bolden(TextTheme t) => TextTheme(
          displayLarge: t.displayLarge?.copyWith(fontWeight: FontWeight.w700),
          displayMedium: t.displayMedium?.copyWith(fontWeight: FontWeight.w700),
          displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.w700),
          headlineLarge: t.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
          headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          bodyLarge: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          bodyMedium: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          bodySmall: t.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          labelMedium: t.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          labelSmall: t.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        );

    return MaterialApp(
      title: 'Custom Collage',
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: primary,
          elevation: 2,
          surfaceTintColor: Colors.transparent, // prevent M3 surface tint
          iconTheme: IconThemeData(color: primary),
          actionsIconTheme: IconThemeData(color: primary),
        ),
        iconTheme: const IconThemeData(color: primary),
        textTheme: _bolden(ThemeData.light().textTheme),
        primaryTextTheme: _bolden(ThemeData.light().primaryTextTheme),
        useMaterial3: true,
      ),
      home: const CollageScreen(),
    );
  }
}
