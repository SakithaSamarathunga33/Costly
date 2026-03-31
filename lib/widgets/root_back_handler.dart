import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// For bottom-nav root screens: system back pops inner routes (e.g. profile sheet),
/// or exits the app when this route is the only one — never navigates to splash.
class RootBackHandler extends StatelessWidget {
  final Widget child;

  const RootBackHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
        } else if (!kIsWeb) {
          SystemNavigator.pop();
        }
      },
      child: child,
    );
  }
}
