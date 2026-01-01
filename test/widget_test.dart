// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_forge/core/providers/image_provider.dart';
import 'package:pdf_forge/core/providers/theme_provider.dart';
import 'package:pdf_forge/features/home/home_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('HomeScreen renders correctly', (WidgetTester tester) async {
    // Create an instance of the AppImageProvider for the test.
    final imageProvider = AppImageProvider();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider.value(value: imageProvider),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Verify that the main components of the HomeScreen are present.
    expect(find.byType(AppBar), findsOneWidget);
    // Let's use the title from the app bar itself for robustness
    expect(find.text('PDF Forge'), findsOneWidget); 
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
  });
}
