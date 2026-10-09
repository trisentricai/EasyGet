import 'package:flutter/material.dart';

void main() {
  runApp(const EasyGetApp());
}

class EasyGetApp extends StatelessWidget {
  const EasyGetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const Scaffold(
        body: Center(child: Text('EASYGET')),
      ),
    );
  }
}
