import 'package:flutter/material.dart';

/// Insets for bottom-aligned dialogs (e.g. New Category) so they sit just above
/// the keyboard without a large gap on tall phones, and respect safe areas when
/// the keyboard is hidden.
EdgeInsets keyboardAwareDialogInsets(BuildContext context) {
  final mq = MediaQuery.of(context);
  final ime = mq.viewInsets.bottom;
  final safeBottom = mq.padding.bottom;
  const horizontal = 24.0;

  if (ime > 0) {
    // IME open: minimal top margin (more room for content), tight gap above keys
    return EdgeInsets.only(
      left: horizontal,
      right: horizontal,
      top: 8,
      bottom: ime + 4,
    );
  }

  // Keyboard hidden: normal margins + home indicator / nav bar
  return EdgeInsets.only(
    left: horizontal,
    right: horizontal,
    top: 24,
    bottom: safeBottom + 12,
  );
}

/// Tight padding so the outer dialog scroll does not hide the icon grid when the
/// field is focused (keyboard open).
EdgeInsets categoryNameFieldScrollPadding(BuildContext context) {
  final ime = MediaQuery.viewInsetsOf(context).bottom;
  return EdgeInsets.fromLTRB(
    8,
    8,
    8,
    ime > 0 ? 2 : 28,
  );
}
