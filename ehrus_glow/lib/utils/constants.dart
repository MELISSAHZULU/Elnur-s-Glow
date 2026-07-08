import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppColors {
  static const Color gold = Color(0xFFC9A96E);
  static const Color goldLight = Color(0xFFE8D5B5);
  static const Color cream = Color(0xFFFDFBF7);
  static const Color charcoal = Color(0xFF2C2C2C);
  static const Color green = Color(0xFF2E7D32);
  static const Color red = Color(0xFFC62828);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color white = Color(0xFFFFFFFF);
}

class AppConstants {
  static const String currencySymbol = 'MK';
  static const String currencyCode = 'MWK';
  
  // Format MWK with commas
  static String formatMwk(int amount) {
    final formatter = NumberFormat.currency(
      symbol: 'MK ',
      decimalDigits: 0,
      locale: 'en_US',
    );
    return formatter.format(amount);
  }
}