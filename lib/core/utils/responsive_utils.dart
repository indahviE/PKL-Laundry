import 'package:flutter/material.dart';

/// Responsive Utilities for NetWash App
/// Helps maintain consistent responsive design across all screens

class ResponsiveUtils {
  // ===== BREAKPOINTS =====
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  // ===== DEVICE TYPE =====
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= mobileBreakpoint &&
        MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  // ===== ORIENTATION =====
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  // ===== PADDING & SPACING =====
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else if (width < tabletBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 32);
    } else {
      return const EdgeInsets.symmetric(horizontal: 48);
    }
  }

  static EdgeInsets getResponsiveVerticalPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(vertical: 16);
    } else {
      return const EdgeInsets.symmetric(vertical: 24);
    }
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return const EdgeInsets.all(16);
    } else if (width < tabletBreakpoint) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  // ===== FONT SIZES =====
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobileSize,
    required double tabletSize,
    required double desktopSize,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return mobileSize;
    } else if (width < tabletBreakpoint) {
      return tabletSize;
    } else {
      return desktopSize;
    }
  }

  // ===== WIDGET SIZING =====
  static double getResponsiveWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return width - 40; // Mobile with padding
    } else if (width < tabletBreakpoint) {
      return width * 0.8; // Tablet: 80% width
    } else {
      return 450; // Desktop: max 450px
    }
  }

  static double getResponsiveButtonHeight(BuildContext context) {
    if (isMobile(context)) {
      return 44;
    } else {
      return 48;
    }
  }

  static double getResponsiveColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return 1;
    } else if (width < tabletBreakpoint) {
      return 2;
    } else {
      return 3;
    }
  }

  // ===== CONTAINER CONSTRAINTS =====
  static BoxConstraints getResponsiveConstraints(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return BoxConstraints(maxWidth: width);
    } else {
      return const BoxConstraints(maxWidth: 450);
    }
  }

  // ===== GAP & SPACING =====
  static double getResponsiveGap(BuildContext context) {
    if (isMobile(context)) {
      return 12;
    } else if (isTablet(context)) {
      return 16;
    } else {
      return 20;
    }
  }

  static double getResponsiveItemSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 8;
    } else {
      return 12;
    }
  }

  // ===== RADIUS =====
  static double getResponsiveBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 8;
    } else {
      return 12;
    }
  }

  // ===== GRID =====
  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return 1;
    } else if (width < tabletBreakpoint) {
      return 2;
    } else {
      return 3;
    }
  }

  static double getGridSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 12;
    } else if (isTablet(context)) {
      return 16;
    } else {
      return 20;
    }
  }

  // ===== SCREEN DIMENSIONS =====
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // ===== KEYBOARD & SAFE AREA =====
  static double getBottomPaddingWithKeyboard(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  // ===== PIXEL RATIO =====
  static double getPixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  // ===== LAYOUT BUILDERS =====
  static Widget responsiveWidget({
    required BuildContext context,
    required Widget mobileWidget,
    required Widget tabletWidget,
    required Widget desktopWidget,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return mobileWidget;
    } else if (width < tabletBreakpoint) {
      return tabletWidget;
    } else {
      return desktopWidget;
    }
  }

  static double responsiveValue({
    required BuildContext context,
    required double mobileValue,
    required double tabletValue,
    required double desktopValue,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return mobileValue;
    } else if (width < tabletBreakpoint) {
      return tabletValue;
    } else {
      return desktopValue;
    }
  }
}

// ===== DEVICE TYPE ENUM =====
enum DeviceType { mobile, tablet, desktop }

// ===== EXTENSION ON BUILDCONTEXT =====
extension ResponsiveExtension on BuildContext {
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  bool get isLandscape => ResponsiveUtils.isLandscape(this);
  bool get isPortrait => ResponsiveUtils.isPortrait(this);

  DeviceType get deviceType => ResponsiveUtils.getDeviceType(this);
  Size get screenSize => ResponsiveUtils.getScreenSize(this);
  double get screenWidth => ResponsiveUtils.getScreenWidth(this);
  double get screenHeight => ResponsiveUtils.getScreenHeight(this);

  EdgeInsets get horizontalPadding =>
      ResponsiveUtils.getResponsiveHorizontalPadding(this);
  EdgeInsets get verticalPadding =>
      ResponsiveUtils.getResponsiveVerticalPadding(this);
  EdgeInsets get allPadding => ResponsiveUtils.getResponsivePadding(this);

  double get gap => ResponsiveUtils.getResponsiveGap(this);
  double get itemSpacing => ResponsiveUtils.getResponsiveItemSpacing(this);
  double get borderRadius =>
      ResponsiveUtils.getResponsiveBorderRadius(this);

  double get bottomPadding =>
      ResponsiveUtils.getBottomPaddingWithKeyboard(this);
  EdgeInsets get safeAreaPadding =>
      ResponsiveUtils.getSafeAreaPadding(this);

  int get gridCrossAxisCount =>
      ResponsiveUtils.getGridCrossAxisCount(this);
  double get gridSpacing => ResponsiveUtils.getGridSpacing(this);
}

// ===== EXAMPLE USAGE =====
/*
// In your widget:

@override
Widget build(BuildContext context) {
  final isMobile = context.isMobile;
  final screenWidth = context.screenWidth;
  final gap = context.gap;

  return Scaffold(
    padding: context.allPadding,
    body: Column(
      spacing: gap,
      children: [
        Text(
          'Hello World',
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              context,
              mobileSize: 16,
              tabletSize: 18,
              desktopSize: 20,
            ),
          ),
        ),
        if (isMobile)
          MobileWidget()
        else if (context.isTablet)
          TabletWidget()
        else
          DesktopWidget(),
      ],
    ),
  );
}
*/