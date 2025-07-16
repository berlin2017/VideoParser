
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'services/scraping_service.dart';
import 'services/local_api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Necessary to initialize MediaKit to create corresponding native instances.
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ScrapingService()),
        Provider(create: (_) => LocalApiService()),
      ],
      child: MaterialApp(
        title: 'Video Browser',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.deepPurple,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            elevation: 0,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
