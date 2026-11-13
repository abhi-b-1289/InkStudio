import 'package:flutter/material.dart';

import 'core/app_constants.dart';
import 'screens/opening_page.dart';

class InkApp extends StatelessWidget {
  const InkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InkStudio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: kPrimary,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF1F2F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF1F2F8),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF1B1B2F),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      home: const OpeningPage(),
    );
  }
}

