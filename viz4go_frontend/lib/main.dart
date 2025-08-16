import 'package:flutter/material.dart';
import 'package:viz4go_frontend/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'viz4go',
      theme: ThemeData(
        colorScheme: const ColorScheme(
          primary: Color(0xFF795548),
          surface: Color(0xFFFAF3E0),
          brightness: Brightness.light,
          error: Color(0xFFD32F2F),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black87,
          onError: Colors.white,
          secondary: Color(0xFF6D4C41),
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
// trzy klasy naraz GO:0030126 GO:0009052
