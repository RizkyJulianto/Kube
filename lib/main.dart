import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:kube/features/auth/ui/splash_screen.dart';
import 'package:kube/features/home/ui/home_screen.dart';
// import 'features/home/ui/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kube App',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),

        textTheme: GoogleFonts.plusJakartaSansTextTheme(Theme.of(context).textTheme)
      ),
      home: const HomeScreen(),
    );
  }
}