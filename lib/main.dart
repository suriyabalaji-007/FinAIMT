import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/screens/home/dashboard_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: FinAIMTApp(),
    ),
  );
}

class FinAIMTApp extends StatelessWidget {
  const FinAIMTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinAIMT',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const DashboardScreen(),
    );
  }
}
