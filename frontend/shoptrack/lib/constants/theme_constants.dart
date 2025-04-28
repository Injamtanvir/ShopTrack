import 'package:flutter/material.dart';

// Dashboard Colors
const Color kPrimaryColor = Color(0xFF3f51b5);
const Color kSecondaryColor = Color(0xFF1a237e);
const Color kAccentColor = Color(0xFF536dfe);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kCardColor = Colors.white;
const Color kTextColor = Color(0xFF333333);
const Color kSecondaryTextColor = Color(0xFF6c757d);

// Dashboard Gradients
const LinearGradient kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF3949AB), Color(0xFF1A237E)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kAccentGradient = LinearGradient(
  colors: [Color(0xFF7986CB), Color(0xFF3F51B5)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kSuccessGradient = LinearGradient(
  colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kWarningGradient = LinearGradient(
  colors: [Color(0xFFFFA726), Color(0xFFF57C00)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kDangerGradient = LinearGradient(
  colors: [Color(0xFFEF5350), Color(0xFFD32F2F)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// New Color Scheme - Updated for more vibrant and attractive colors
const Color kNewPrimaryColor = Color(0xFF1E88E5); // Vibrant blue 
const Color kNewSecondaryColor = Color(0xFF26A69A); // Teal accent
const Color kNewAccentColor = Color(0xFFFFAB00);   // Amber accent
const Color kNewBackgroundColor = Color(0xFFF5F7FA); // Light gray background
const Color kNewCardColor = Colors.white;
const Color kNewTextColor = Color(0xFF212121); // Darker text
const Color kNewSecondaryTextColor = Color(0xFF757575); // Gray text
const Color kNewSuccessColor = Color(0xFF66BB6A); // Success green
const Color kNewErrorColor = Color(0xFFEF5350);   // Error red
const Color kNewWarningColor = Color(0xFFFFA726); // Warning orange
const Color kNewInfoColor = Color(0xFF42A5F5);    // Info blue

// Dashboard Box Shadows
final List<BoxShadow> kCardShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.07),
    blurRadius: 8,
    offset: const Offset(0, 3),
  ),
];

// Dashboard Gradients - Updated for modern look
const LinearGradient kNewPrimaryGradient = LinearGradient(
  colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kNewSecondaryGradient = LinearGradient(
  colors: [Color(0xFF26A69A), Color(0xFF00897B)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kNewAccentGradient = LinearGradient(
  colors: [Color(0xFFFFAB00), Color(0xFFFF9100)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Role-specific colors
const Color kOwnerRoleColor = Color(0xFFE53935); // Red
const Color kManagerRoleColor = Color(0xFF1E88E5); // Blue
const Color kSellerRoleColor = Color(0xFF43A047); // Green 

// Feature-specific colors
const Color kProductsColor = Color(0xFF4CAF50); // Green
const Color kSalesColor = Color(0xFF2196F3);    // Blue
const Color kInvoiceColor = Color(0xFF9C27B0);  // Purple
const Color kPriceColor = Color(0xFFFF9800);    // Orange
const Color kPendingColor = Color(0xFFFFC107);  // Amber
const Color kHistoryColor = Color(0xFF607D8B);  // Blue Gray 