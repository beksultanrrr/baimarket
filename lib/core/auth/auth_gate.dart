import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/live/presentation/widgets/live_shopping_scope.dart';

import '../../l10n/app_localizations.dart';
import '../app_pallete.dart';
import '../secure_token_storage.dart';
import 'pending_action.dart';

/// Returns true if the user is already authenticated.
///
/// Otherwise stores the optional [pendingAction] (to be replayed after the
/// user logs in), shows a "Login required" bottom sheet, and returns false.
/// Callers must check the return value and skip the protected work when false.
Future<bool> ensureAuthenticated(
  BuildContext context, {
  VoidCallback? pendingAction,
}) async {
  final token = await getAuthToken();
  if (token != null) return true;

  if (pendingAction != null) {
    PendingAuthAction.set(pendingAction);
  }
  if (!context.mounted) return false;
  await _showLoginRequiredSheet(context);
  return false;
}

Future<void> _showLoginRequiredSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n.loginRequired,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  fontFamily: 'Gilroy',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.loginRequiredHint,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                  fontFamily: 'Gilroy',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  color: mainColorLight,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () {
                    Navigator.of(sheetCtx).pop();
                    // Иначе шиты эфира остаются поверх экрана авторизации.
                    closeLiveSheetsFrom(sheetCtx);
                    sheetCtx.go('/auth');
                  },
                  child: Text(
                    l10n.login,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              CupertinoButton(
                onPressed: () {
                  PendingAuthAction.clear();
                  Navigator.of(sheetCtx).pop();
                },
                child: Text(
                  l10n.cancel,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
