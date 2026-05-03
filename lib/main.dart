import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_gate.dart';
import 'services/stock_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // ⭐ Supabase 초기화 (KIS/OpenDART 초기화 코드는 다 사라짐)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

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
      home: const OnboardingGate(),
    );
  }
}