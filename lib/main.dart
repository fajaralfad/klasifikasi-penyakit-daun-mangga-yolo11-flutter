import 'package:flutter/material.dart';
import 'screens/disease_detection_page.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mango Leaf Disease Detector',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: DiseaseDetectionPage(), 
      debugShowCheckedModeBanner: false,
    );
  }
}