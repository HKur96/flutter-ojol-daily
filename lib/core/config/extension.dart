import 'package:flutter/material.dart';

// Mockup design size
const mockupHeight = 844;
const mockupWidth = 390;
extension ScreenUtil on BuildContext {
  bool get isMobile => MediaQuery.of(this).size.width < 600;

  double get deviceWidth => MediaQuery.of(this).size.width;

  double get deviceHeight => MediaQuery.of(this).size.height;

  double get dw => MediaQuery.of(this).size.width;

  double get dh => MediaQuery.of(this).size.height;

  Orientation get orientation => MediaQuery.of(this).orientation;

  bool get isLandscape => orientation == Orientation.landscape;

  double dp(double size) => size / mockupWidth * dw;

  // Text and Color Theme data
  TextTheme get text => Theme.of(this).textTheme;

  Color get primaryColor => Theme.of(this).colorScheme.primary;

  Color get primaryContainer => Theme.of(this).colorScheme.primaryContainer;

  Color get inversePrimary => Theme.of(this).colorScheme.inversePrimary;

  Color get secondaryColor => Theme.of(this).colorScheme.secondary;

  Color get secondaryContainer => Theme.of(this).colorScheme.secondaryContainer;

  Color get tertiaryColor => Theme.of(this).colorScheme.tertiary;

  Color get tertiaryContainer => Theme.of(this).colorScheme.tertiaryContainer;

  Color get surface => Theme.of(this).colorScheme.surface;

  // ignore: deprecated_member_use
  Color get surfaceVariant => Theme.of(this).colorScheme.surfaceVariant;

  Color get inverseSurface => Theme.of(this).colorScheme.inverseSurface;

  Color get errorColor => Theme.of(this).colorScheme.error;

  Color get errorContainer => Theme.of(this).colorScheme.errorContainer;

  // ignore: deprecated_member_use
  Color get background => Theme.of(this).colorScheme.background;

  Color get outline => Theme.of(this).colorScheme.outline;

  Color get hintColor => Theme.of(this).hintColor;

  Color get disableColor => Theme.of(this).disabledColor;

  // Text and Icon Color
  Color get onPrimary => Theme.of(this).colorScheme.onPrimary;

  Color get onPrimaryContainer => Theme.of(this).colorScheme.onPrimaryContainer;

  Color get onSecondary => Theme.of(this).colorScheme.onSecondary;

  Color get onSecondaryContainer =>
      Theme.of(this).colorScheme.onSecondaryContainer;

  Color get onTertiary => Theme.of(this).colorScheme.onTertiary;

  Color get onTertiaryContainer =>
      Theme.of(this).colorScheme.onTertiaryContainer;

  Color get onError => Theme.of(this).colorScheme.onError;

  Color get onErrorContainer => Theme.of(this).colorScheme.onErrorContainer;

  // ignore: deprecated_member_use
  Color get onBackground => Theme.of(this).colorScheme.onBackground;

  Color get onSurface => Theme.of(this).colorScheme.onSurface;

  Color get onSurfaceVariant => Theme.of(this).colorScheme.onSurfaceVariant;

  Color get onInverseSurface => Theme.of(this).colorScheme.onInverseSurface;
}

extension ImageUtil on String {
  String get icon => 'assets/icons/$this.png';

  String get image => 'assets/images/$this.png';
}
