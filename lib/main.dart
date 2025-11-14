import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/collage_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/collage_manager.dart';
import 'services/purchase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding =
      prefs.getBool(OnboardingScreen.onboardingSeenKey) ?? false;
  runApp(MyApp(initialOnboardingSeen: hasSeenOnboarding));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.initialOnboardingSeen = false});

  final bool initialOnboardingSeen;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _hasSeenOnboarding = widget.initialOnboardingSeen;
  }

  Future<void> _handleOnboardingCompleted() async {
    if (!mounted) return;
    setState(() {
      _hasSeenOnboarding = true;
    });
  }

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
        ChangeNotifierProvider(create: (_) => PurchaseService()..initialize()),
        ChangeNotifierProxyProvider<PurchaseService, CollageManager>(
          create: (_) => CollageManager(),
          update: (_, purchaseService, collageManager) {
            final CollageManager manager = collageManager ?? CollageManager();
            if (purchaseService.activePlanProductId != null) {
              final productDetails = purchaseService.productForId(
                purchaseService.activePlanProductId!,
              );
              manager.setPremiumName(productDetails?.title ?? '');
            }

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
            ThemeData.light().textTheme.apply(
              bodyColor: primary,
              displayColor: primary,
            ),
          ),
          primaryTextTheme: bolden(
            ThemeData.light().primaryTextTheme.apply(
              bodyColor: primary,
              displayColor: primary,
            ),
          ),
          useMaterial3: true,
        ),
        home: _hasSeenOnboarding
            ? const CollageScreen()
            : OnboardingScreen(
                onFinished: _handleOnboardingCompleted,
              ),
      ),
    );
  }
}
