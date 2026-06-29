import 'package:flutter/material.dart';

class AppStyles {
  // Neumorphic / Soft UI Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFFD3B8FE).withOpacity(0.5),
      offset: const Offset(5, 5),
      blurRadius: 15,
      spreadRadius: 1,
    ),
    const BoxShadow(
      color: Colors.white,
      offset: Offset(-5, -5),
      blurRadius: 15,
      spreadRadius: 1,
    ),
  ];

  static List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: const Color(0xFF7A3FF3).withOpacity(0.25),
      blurRadius: 25,
      offset: const Offset(0, 15),
      spreadRadius: -5,
    ),
  ];
  
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.grey.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
}
