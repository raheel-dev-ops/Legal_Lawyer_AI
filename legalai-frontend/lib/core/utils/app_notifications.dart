import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppNotifications {
  AppNotifications._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static const Duration defaultDuration = Duration(seconds: 1);

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showMessage(
    String message, {
    SnackBarAction? action,
    Duration duration = defaultDuration,
  }) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return null;
    HapticFeedback.selectionClick();
    messenger.clearSnackBars();
    _forceRemoveAfter(messenger, duration);
    final theme = Theme.of(messenger.context);
    return messenger.showSnackBar(
      _withDuration(
        SnackBar(content: Text(message), duration: duration, action: action),
        duration,
        theme,
      ),
    );
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
  showSnackBar(
    BuildContext context,
    SnackBar snackBar, {
    Duration duration = defaultDuration,
  }) {
    final messenger =
        ScaffoldMessenger.maybeOf(context) ?? messengerKey.currentState;
    if (messenger == null) return null;
    HapticFeedback.selectionClick();
    messenger.clearSnackBars();
    _forceRemoveAfter(messenger, duration);
    return messenger.showSnackBar(
      _withDuration(snackBar, duration, Theme.of(messenger.context)),
    );
  }

  static SnackBar _withDuration(
    SnackBar snackBar,
    Duration duration,
    ThemeData theme,
  ) {
    final themeData = theme.snackBarTheme;
    final contentStyle = themeData.contentTextStyle;
    final fallbackBackground = theme.colorScheme.inverseSurface;
    final content = contentStyle == null
        ? snackBar.content
        : DefaultTextStyle.merge(style: contentStyle, child: snackBar.content);
    return SnackBar(
      content: content,
      backgroundColor:
          snackBar.backgroundColor ??
          themeData.backgroundColor ??
          fallbackBackground,
      elevation: snackBar.elevation,
      margin: snackBar.margin,
      padding: snackBar.padding,
      width: snackBar.width,
      shape: snackBar.shape,
      behavior: snackBar.behavior,
      action: snackBar.action,
      duration: duration,
      animation: snackBar.animation,
      onVisible: snackBar.onVisible,
      dismissDirection: snackBar.dismissDirection,
      showCloseIcon: snackBar.showCloseIcon,
      closeIconColor: snackBar.closeIconColor,
      actionOverflowThreshold: snackBar.actionOverflowThreshold,
    );
  }

  static void _forceRemoveAfter(
    ScaffoldMessengerState messenger,
    Duration duration,
  ) {
    Future.delayed(duration, () {
      if (!messenger.mounted) return;
      messenger.removeCurrentSnackBar();
    });
  }
}
