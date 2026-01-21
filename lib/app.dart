import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/providers.dart';
import 'presentation/screens/home_screen.dart';

/// アプリケーションウィジェット
class SpaceWeatherApp extends ConsumerWidget {
  const SpaceWeatherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Space Weather App',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
