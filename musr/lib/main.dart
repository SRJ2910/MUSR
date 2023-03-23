import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:musr/pages/splash.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
      apiKey: "AIzaSyCAhmosE1zvz9PeDnKfUmuo_LQD2FLVoGw",
      appId: "1:1025672671681:web:003fd45c549f8df14bbf40",
      messagingSenderId: "1025672671681",
      projectId: "musr-669d8",
    ));
  } else {
    if (Platform.isAndroid) {
      await Firebase.initializeApp();
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MUSR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
      home: const Scaffold(
        body: spalshscreen(),
      ),
    );
  }
}
