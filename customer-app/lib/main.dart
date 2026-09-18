import 'package:flutter/material.dart';

void main() => runApp(const EasyGetApp());

class EasyGetApp extends StatelessWidget {
  const EasyGetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EASYGET',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('EASYGET', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Essentials, delivered quickly.'),
          ]),
        ),
      ),
    );
  }
}
