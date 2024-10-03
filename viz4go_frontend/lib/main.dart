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
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: const ColorScheme(
          primary: Color(0xFF795548), // Ciemny brąz, elegancki i neutralny
          surface: Color(0xFFFAF3E0), // Jasny beżowy, delikatne tło
          brightness: Brightness.light,
          error: Color(0xFFD32F2F), // Stonowany, ale wyraźny odcień czerwieni
          onPrimary: Colors.white, // Dobrze widoczny na ciemnym tle
          onSecondary: Colors
              .white, // Jasny tekst na ciemniejszych elementach pomocniczych
          onSurface: Colors
              .black87, // Lekko przyciemniony czarny dla dobrej czytelności
          onError:
              Colors.white, // Biały dla dobrej widoczności na czerwonym tle
          secondary: Color(0xFF6D4C41), // Ciemniejszy brąz jako kolor akcentowy
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
// trzy klasy naraz GO:0030126 GO:0009052
