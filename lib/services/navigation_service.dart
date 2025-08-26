import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> navigateTo(String routeName, {Object? arguments}) async {
    final state = navigatorKey.currentState;
    if (state == null) {
      return;
    }
    try {
      await state.pushNamed(routeName, arguments: arguments);
    } catch (_) {
      // Ignore navigation errors in background contexts
    }
  }
}


