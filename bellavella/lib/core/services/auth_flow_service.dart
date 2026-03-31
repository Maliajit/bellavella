import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../routes/app_routes.dart';

class PendingAuthAction {
  final String routeName;
  final Map<String, String> pathParameters;
  final Object? extra;
  final String actionType;
  final Map<String, dynamic> payload;

  const PendingAuthAction({
    required this.routeName,
    this.pathParameters = const {},
    this.extra,
    required this.actionType,
    this.payload = const {},
  });
}

class AuthFlowService {
  static const String _pendingActionKey = 'pending_auth_action';
  static PendingAuthAction? _pendingAction;
  static bool _loaded = false;

  static PendingAuthAction? get pendingAction => _pendingAction;

  static Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingActionKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final json = jsonDecode(raw);
        if (json is Map<String, dynamic>) {
          _pendingAction = PendingAuthAction(
            routeName: json['route_name']?.toString() ?? AppRoutes.clientHomeName,
            pathParameters: Map<String, String>.from(
              (json['path_parameters'] as Map?) ?? const {},
            ),
            extra: json['extra'],
            actionType: json['action_type']?.toString() ?? '',
            payload: Map<String, dynamic>.from(
              (json['payload'] as Map?) ?? const {},
            ),
          );
        }
      } catch (_) {
        _pendingAction = null;
      }
    }

    _loaded = true;
  }

  static Future<void> setPendingAction(PendingAuthAction action) async {
    await _ensureLoaded();
    _pendingAction = action;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingActionKey,
      jsonEncode({
        'route_name': action.routeName,
        'path_parameters': action.pathParameters,
        'extra': action.extra,
        'action_type': action.actionType,
        'payload': action.payload,
      }),
    );
  }

  static Future<void> clearPendingAction() async {
    await _ensureLoaded();
    _pendingAction = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingActionKey);
  }

  static Future<PendingAuthAction?> consumeIf(
    bool Function(PendingAuthAction action) matcher,
  ) async {
    await _ensureLoaded();
    final action = _pendingAction;
    if (action == null || !matcher(action)) {
      return null;
    }
    _pendingAction = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingActionKey);
    return action;
  }

  static Future<void> continueAfterClientAuth(BuildContext context) async {
    await _ensureLoaded();
    final pending = _pendingAction;
    if (pending == null) {
      context.go(AppRoutes.clientHome);
      return;
    }

    context.goNamed(
      pending.routeName,
      pathParameters: pending.pathParameters,
      extra: pending.extra,
    );
  }
}
