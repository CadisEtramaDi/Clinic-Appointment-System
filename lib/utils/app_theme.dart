import 'package:flutter/material.dart';

/// Centralized theme and color configuration for the entire app
class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF2D5AEE);
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFFEFF6FF);

  // Background Colors
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color scaffoldBackground = Color(0xFFF8FAFC);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFCBD5E1);

  // Status Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  // Semantic Colors
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentRed = Color(0xFFDC2626);

  // Neutral Colors
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE5E5E5);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral800 = Color(0xFF424242);
  static const Color neutral900 = Color(0xFF212121);

  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXL = 24.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 12.0;
  static const double spacingLG = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacing2XL = 32.0;
  static const double spacing3XL = 40.0;

  // Icon Sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXL = 48.0;
  static const double iconSize2XL = 64.0;

  // Font Sizes
  static const double fontSizeXS = 10.0;
  static const double fontSizeSM = 12.0;
  static const double fontSizeMD = 14.0;
  static const double fontSizeLG = 16.0;
  static const double fontSizeXL = 18.0;
  static const double fontSize2XL = 20.0;
  static const double fontSize3XL = 24.0;
  static const double fontSize4XL = 28.0;

  // Shadows
  static final BoxShadow shadowSmall = BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 4,
    offset: const Offset(0, 2),
  );

  static final BoxShadow shadowMedium = BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 8,
    offset: const Offset(0, 4),
  );

  static final BoxShadow shadowLarge = BoxShadow(
    color: Colors.black.withOpacity(0.15),
    blurRadius: 16,
    offset: const Offset(0, 8),
  );

  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // Animation Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  // Border Styles
  static const BorderSide borderDefault = BorderSide(
    color: neutral200,
    width: 1.0,
  );

  static const BorderSide borderPrimary = BorderSide(
    color: primaryColor,
    width: 1.5,
  );

  // Gradient Definitions
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [primaryColor, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientSuccess = LinearGradient(
    colors: [successColor, accentGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: fontSize4XL,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: fontSize3XL,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: fontSize2XL,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: fontSizeXL,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: fontSizeLG,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: fontSizeMD,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: fontSizeLG,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: fontSizeMD,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: fontSizeSM,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: fontSizeMD,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: fontSizeSM,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: fontSizeXS,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  // Opacity Values
  static const double opacityDisabled = 0.5;
  static const double opacityHover = 0.08;
  static const double opacityPressed = 0.12;

  // Button Heights
  static const double buttonHeightSmall = 32.0;
  static const double buttonHeightMedium = 40.0;
  static const double buttonHeightLarge = 48.0;
  static const double buttonHeightXL = 56.0;

  // Input Heights
  static const double inputHeightSmall = 36.0;
  static const double inputHeightMedium = 44.0;
  static const double inputHeightLarge = 52.0;

  // Chip Sizes
  static const double chipHeightSmall = 28.0;
  static const double chipHeightMedium = 32.0;
  static const double chipHeightLarge = 36.0;

  // Card Dimensions
  static const double cardHeightSmall = 80.0;
  static const double cardHeightMedium = 120.0;
  static const double cardHeightLarge = 160.0;

  // Action Color Map (for dynamic action coloring in audit trail, etc.)
  static final Map<String, Color> actionColorMap = {
    'view': infoColor,
    'edit': warningColor,
    'delete': errorColor,
    'archive': accentPurple,
    'export': accentCyan,
    'transfer': accentGreen,
    'approve': successColor,
    'reject': errorColor,
    'restore': accentOrange,
    'create': successColor,
  };

  // Action Icon Map
  static final Map<String, IconData> actionIconMap = {
    'view': Icons.visibility,
    'edit': Icons.edit,
    'delete': Icons.delete,
    'archive': Icons.archive,
    'export': Icons.download,
    'transfer': Icons.swap_horiz,
    'approve': Icons.check_circle,
    'reject': Icons.cancel,
    'restore': Icons.restore,
    'create': Icons.add_circle,
  };

  // Status Color Map
  static final Map<String, Color> statusColorMap = {
    'active': successColor,
    'inactive': textSecondary,
    'archived': neutral500,
    'pending': warningColor,
    'approved': successColor,
    'rejected': errorColor,
    'completed': successColor,
  };

  // Status Icon Map
  static final Map<String, IconData> statusIconMap = {
    'active': Icons.check_circle,
    'inactive': Icons.cancel,
    'archived': Icons.archive,
    'pending': Icons.hourglass_empty,
    'approved': Icons.check_circle,
    'rejected': Icons.cancel,
    'completed': Icons.task_alt,
  };
}

/// Theme configuration class for easy switching between themes
class ThemeConfig {
  static ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppTheme.primaryColor,
      scaffoldBackgroundColor: AppTheme.scaffoldBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTheme.titleLarge,
        iconTheme: IconThemeData(color: AppTheme.primaryColor),
      ),
      textTheme: const TextTheme(
        displayLarge: AppTheme.headlineLarge,
        displayMedium: AppTheme.headlineMedium,
        displaySmall: AppTheme.headlineSmall,
        headlineMedium: AppTheme.titleLarge,
        headlineSmall: AppTheme.titleMedium,
        titleLarge: AppTheme.titleSmall,
        titleMedium: AppTheme.bodyLarge,
        titleSmall: AppTheme.bodyMedium,
        bodyLarge: AppTheme.bodyLarge,
        bodyMedium: AppTheme.bodyMedium,
        bodySmall: AppTheme.bodySmall,
        labelLarge: AppTheme.labelLarge,
        labelMedium: AppTheme.labelMedium,
        labelSmall: AppTheme.labelSmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLG,
            vertical: AppTheme.spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: const BorderSide(color: AppTheme.primaryColor),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLG,
            vertical: AppTheme.spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.neutral50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          borderSide: AppTheme.borderDefault,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          borderSide: AppTheme.borderDefault,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          borderSide: AppTheme.borderPrimary,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppTheme.neutral200,
        disabledColor: AppTheme.neutral300,
        selectedColor: AppTheme.primaryColor,
        secondarySelectedColor: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMD,
          vertical: AppTheme.spacingSM,
        ),
        labelStyle: AppTheme.bodySmall,
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(
        color: AppTheme.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          side: AppTheme.borderDefault,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppTheme.neutral200,
        thickness: 1,
        space: AppTheme.spacingMD,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppTheme.primaryColor,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
