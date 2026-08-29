import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette: Royal Indigo, Electric Iris & Modern Cyan
  static const Color primary = Color(0xFF4F46E5); // Rich Royal Indigo
  static const Color primaryLight = Color(0xFF6366F1); // Bright Iris Blue
  static const Color primaryDark = Color(0xFF3730A3); // Deep Indigo
  static const Color secondary = Color(0xFF0EA5E9); // Electric Sky Cyan
  static const Color accent = Color(0xFF8B5CF6); // Vibrant Violet Accent
  static const Color roseAccent = Color(0xFFF43F5E); // Luxury Rose Accent

  // Background & Surface (Pure, Crisp, & Ultra Modern Light)
  static const Color backgroundLight = Color(0xFFF8FAFC); // Crisp Alabaster
  static const Color surfaceLight = Colors.white;
  static const Color cardLight = Colors.white;
  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF131B2E);

  // Borders & Dividers
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF2D3748);
  static const Color dividerLight = Color(0xFFF1F5F9);
  static const Color dividerDark = Color(0xFF1E293B);

  // Status Colors (Vibrant, Accessible & Clear)
  static const Color statusPending = Color(0xFFD97706); // Warm Amber Gold
  static const Color statusPendingBg = Color(0xFFFFFBEB);
  static const Color statusPendingBorder = Color(0xFFFDE68A);
  
  static const Color statusApproved = Color(0xFF059669); // Rich Emerald
  static const Color statusApprovedBg = Color(0xFFECFDF5);
  static const Color statusApprovedBorder = Color(0xFFA7F3D0);
  
  static const Color statusRejected = Color(0xFFE11D48); // Rose Crimson
  static const Color statusRejectedBg = Color(0xFFFFF1F2);
  static const Color statusRejectedBorder = Color(0xFFFECDD3);

  static const Color statusSubmitted = Color(0xFF4F46E5); // Indigo Blue
  static const Color statusSubmittedBg = Color(0xFFEEF2FF);
  static const Color statusSubmittedBorder = Color(0xFFC7D2FE);

  static const Color statusCancelled = Color(0xFF64748B); // Slate Gray
  static const Color statusCancelledBg = Color(0xFFF1F5F9);
  static const Color statusCancelledBorder = Color(0xFFCBD5E1);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A); // Deep Slate Charcoal
  static const Color textSecondaryLight = Color(0xFF64748B); // Medium Slate
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3730A3), Color(0xFF4F46E5), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient luxuryGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Neo-Brutalism Design System Tokens
  static const Color neoBorder = Color(0xFF0F172A); // High-contrast solid border
  static const Color neoBorderLight = Color(0xFF0F172A);
  static const Color neoBorderDark = Color(0xFFF8FAFC);
  static const Color neoShadow = Color(0xFF0F172A); // Hard zero-blur shadow
  static const Color neoBgLight = Color(0xFFFFFDF5); // Warm retro alabaster canvas
  static const Color neoBgDark = Color(0xFF0B0F19);
  
  // Neo Pop Pastels & Accents
  static const Color neoYellow = Color(0xFFFFDE59); // Electric Sun Yellow
  static const Color neoPink = Color(0xFFFF66C4);   // Hot Cyber Pink
  static const Color neoCyan = Color(0xFF00F0FF);   // Vivid Electric Cyan
  static const Color neoGreen = Color(0xFF00E676);  // Bold Neo Mint Green
  static const Color neoPurple = Color(0xFF8C52FF); // Electric Violet
  static const Color neoOrange = Color(0xFFFF914D); // Retro Pop Orange
  static const Color neoIndigo = Color(0xFF4F46E5); // Pure Neo Indigo
}
