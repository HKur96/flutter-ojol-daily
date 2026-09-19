import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void gSetDeviceOrientations({required bool isLandscape}) {
  if (isLandscape) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } else {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    required this.tablet,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraint) {
        if (constraint.maxWidth >= 600) {
          gSetDeviceOrientations(isLandscape: true);
          return tablet;
        }
        
        return mobile;
      },
    );
  }
}
