import 'package:flutter/material.dart';

class AppButtonTokens {
  static const double radius = 12;
  static const double minHeight = 48;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
  static const TextStyle textStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const RoundedRectangleBorder shape =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radius)));

  const AppButtonTokens._();
}
