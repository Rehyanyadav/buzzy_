import 'package:buzzy/screens/homescreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "OpenSans",
        primaryColor: Color.fromARGB(255, 255, 196, 0),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Color.fromARGB(255, 255, 217, 0),
        ),
      ),

      home: HomeScreen(),
    );
  }
}
