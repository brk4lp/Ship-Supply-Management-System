import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Flutter Rust Bridge
  await RustLib.init();
  
  runApp(
    const ProviderScope(
      child: SSMSApp(),
    ),
  );
}

class SSMSApp extends ConsumerWidget {
  const SSMSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'SSMS - Gemi Kumanya Yönetimi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}

/// Helper to check platform for adaptive layouts
class PlatformHelper {
  static bool get isDesktop => Platform.isWindows || Platform.isMacOS;
  static bool get isMobile => Platform.isIOS;
  static bool get isWindows => Platform.isWindows;
  static bool get isIOS => Platform.isIOS;
}
