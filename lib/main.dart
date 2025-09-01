import 'package:flutter/material.dart';
import 'screens/collage_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // App-wide color palette
    const primary = Color(0xFF5D688A); // #5D688A
    const secondary = Color(0xFFF7A5A5); // #F7A5A5
    const tertiary = Color(0xFFFFDBB6); // #FFDBB6 (accent)
    const surface = Color(0xFFFFF2EF); // #FFF2EF

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

    return MaterialApp(
      title: 'Photo Collage',
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
        useMaterial3: true,
      ),
      home: const CollageScreen(),
    );
  }
}
