import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/app_pallete.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/cart_change_model.dart';
import '../cubit/cart_cubit.dart';

/// Показывает сообщения корзины поверх любого экрана.
///
/// Смонтирован в `MaterialApp.builder`, поэтому работает и там, где сама
/// корзина не открыта, — например, когда `changes` приезжают при оформлении
/// заказа из плашки на странице эфира.
class CartEventListener extends StatefulWidget {
  const CartEventListener({super.key, required this.child});

  final Widget child;

  @override
  State<CartEventListener> createState() => _CartEventListenerState();
}

enum _Severity { error, info }

class _CartEventListenerState extends State<CartEventListener> {
  StreamSubscription<CartEvent>? _sub;
  CartCubit? _cubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cubit = context.read<CartCubit>();
    if (_cubit == cubit) return;
    _sub?.cancel();
    _cubit = cubit;
    _sub = cubit.events.listen(_handle);
  }

  void _handle(CartEvent event) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final String text;
    var severity = _Severity.error;
    switch (event) {
      case CartAddFailedEvent():
        text = l10n.addToCartFailed;
      case CartRemoveFailedEvent():
        text = l10n.removeFromCartFailed;
      case CartAddUnauthenticatedEvent():
        text = l10n.loginRequired;
      case CartWriteRejectedEvent(:final message, :final statusCode):
        // Сообщения сервера приходят по-английски; известные случаи из
        // контракта переводим, остальное показываем как есть.
        text = _localizeServerMessage(l10n, message, statusCode);
      case CartQuantityChangeFailedEvent():
        text = l10n.cartQuantityChangeFailed;
      case CartClearFailedEvent():
        text = l10n.cartClearFailed;
      case CartRefreshFailedEvent():
        text = l10n.cartRefreshFailed;
      case CartEmptyOnCheckoutEvent():
        text = l10n.cartEmpty;
        severity = _Severity.info;
      case CartChangesEvent(:final changes):
        final message = _describeChanges(l10n, changes);
        if (message == null) return;
        text = message;
        severity = _Severity.info;
    }

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            text,
            style: const TextStyle(fontFamily: 'Gilroy'),
          ),
          backgroundColor:
              severity == _Severity.error ? Colors.redAccent : darkButtonColor,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: severity == _Severity.error ? 2 : 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  String _localizeServerMessage(
    AppLocalizations l10n,
    String message,
    int? statusCode,
  ) {
    final lower = message.toLowerCase();
    if (lower.contains('not enough items in stock')) {
      return l10n.cartNotEnoughStock;
    }
    if (lower.contains('model not found') || statusCode == 404) {
      return l10n.productUnavailable;
    }
    return message;
  }

  /// Из `changes` показываем только первое понятное изменение — снекбар не
  /// место для списка. Полный перечень виден на самой странице корзины.
  String? _describeChanges(
    AppLocalizations l10n,
    List<CartChangeModel> changes,
  ) {
    for (final change in changes) {
      final name = change.name;
      if (name == null || name.isEmpty) continue;
      switch (change.kind) {
        case CartChangeKind.removed:
          return l10n.cartItemRemovedByStock(name);
        case CartChangeKind.quantityReduced:
          return l10n.cartItemQuantityReduced(
            name,
            (change.newQuantity ?? 0).toString(),
          );
        case CartChangeKind.priceChanged:
          return l10n.cartItemPriceChanged(name);
        case CartChangeKind.unknown:
          continue;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
