import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.red, brightness: Brightness.dark),
);
