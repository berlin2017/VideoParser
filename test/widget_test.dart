import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_browser_app/main.dart';
import 'package:video_browser_app/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen shows a logo and title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the SplashScreen is shown.
    expect(find.byType(SplashScreen), findsOneWidget);

    // Verify that our logo and title are present.
    expect(find.byType(FlutterLogo), findsOneWidget);
    expect(find.text('Video Browser'), findsOneWidget);

    // Wait for the timer to complete.
    await tester.pump(const Duration(seconds: 4));
  });
}