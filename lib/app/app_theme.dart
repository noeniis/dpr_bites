import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color gradientStart = Color(0xFFFFFFFF);
  static const Color gradientEnd = Color(0xFFFFA1A1);
  static const Color primaryColor = Color(0xFFD53D3D); 
  static const Color textColor = Color(0xFF602829);

  static ThemeData mainTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      bodyMedium: GoogleFonts.poppins(color: textColor),
      bodyLarge: GoogleFonts.poppins(color: textColor),
      titleLarge: GoogleFonts.poppins(
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: primaryColor,
      secondary: gradientEnd,
    ),
  );
}
