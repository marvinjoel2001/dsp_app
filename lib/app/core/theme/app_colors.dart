import 'package:flutter/material.dart';

class AppColors {
  // Chiringuito Emerald Palette
  static const Color primary = Color(0xFF059669); // Emerald 600
  static const Color primaryDark = Color(0xFF065F46); // Emerald 800
  static const Color primaryLight = Color(0xFFECFDF5); // Emerald 50
  static const Color primaryDeep = Color(0xFF022C22); // Emerald 950

  // Secondary Accents (Warm Amber / Orange for Pickups & Alerts)
  static const Color secondary = Color(0xFFF59E0B);
  static const Color secondaryLight = Color(0xFFFEF3C7);
  static const Color secondaryDark = Color(0xFFD97706);

  // Status & Alerts
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFEFF6FF);

  // Light Mode Surfaces & Depth
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderLight = Color(0xFFF1F5F9); // Slate 100

  // High-Contrast Typography (Garantiza legibilidad en Modo Light)
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900 - Casi negro de alto contraste
  static const Color textSecondary = Color(0xFF334155); // Slate 700 - Texto secundario nítido
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textInverted = Color(0xFFFFFFFF); // Blanco exclusivo para botones oscuros/primarios

  // Mapbox Styling
  static const Color routePolyline = Color(0xFF059669);
  static const Color mapBackground = Color(0xFFF1F5F9);
}
