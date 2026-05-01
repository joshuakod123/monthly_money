import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_gate.dart';
import 'services/stock_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await StockDataService.instance.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: DividendApp()));
}

class DividendApp extends StatelessWidget {
  const DividendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '배당나무',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const OnboardingGate(), // 👈 퀴즈 게이트가 첫 화면
    );
  }
}