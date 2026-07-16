import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/app_logger.dart';
import '../../data/datasources/kaspi_payment_service.dart';

part 'kaspi_payment_state.dart';

/// Управляет оплатой заказа через Kaspi: держит актуальный `redirectUrl`
/// (для QR/кнопки) и опрашивает статус заказа `GET /order/{id}`.
///
/// Маппинг статусов:
/// - `PROCESSING` / `PICKUP` → оплачено (`KaspiStatus.paid`)
/// - `PAYMENT_FAILED`        → не оплачено (`KaspiStatus.failed`)
/// - `PAYMENT_PENDING`       → остаёмся в ожидании
///
/// Ссылка Kaspi живёт ~15 минут → по таймеру переходим в `expired`.
/// `retry()` берёт новый `redirectUrl` через `pay/again` и перезапускает опрос.
class KaspiPaymentCubit extends Cubit<KaspiPaymentState> {
  KaspiPaymentCubit({
    required int orderId,
    required String redirectUrl,
    KaspiPaymentService? service,
    Duration pollInterval = const Duration(seconds: 3),
    Duration linkLifetime = const Duration(minutes: 15),
  })  : _orderId = orderId,
        _service = service ?? KaspiPaymentService(),
        _pollInterval = pollInterval,
        _linkLifetime = linkLifetime,
        super(KaspiPaymentState.pending(redirectUrl)) {
    _startTimers();
  }

  final int _orderId;
  final KaspiPaymentService _service;
  final Duration _pollInterval;
  final Duration _linkLifetime;

  Timer? _poller;
  Timer? _expiry;
  bool _settled = false; // оплачено — больше не опрашиваем

  void _startTimers() {
    _poller?.cancel();
    _expiry?.cancel();
    _poller = Timer.periodic(_pollInterval, (_) => _tick());
    _expiry = Timer(_linkLifetime, _onExpired);
  }

  Future<void> _tick() async {
    if (_settled) return;
    final status = await _service.getOrderStatus(_orderId);
    paymentLog.event('kaspi poll', 'order=$_orderId status=$status');
    if (_settled || isClosed) return;
    switch (status) {
      case 'PROCESSING':
      case 'PICKUP':
        _settled = true;
        _poller?.cancel();
        _expiry?.cancel();
        emit(const KaspiPaymentState.paid());
        break;
      case 'PAYMENT_FAILED':
        _poller?.cancel();
        _expiry?.cancel();
        emit(const KaspiPaymentState.failed());
        break;
      default:
        // PAYMENT_PENDING / null — продолжаем ждать.
        break;
    }
  }

  void _onExpired() {
    if (_settled || isClosed) return;
    _poller?.cancel();
    emit(const KaspiPaymentState.expired());
  }

  /// Повторить оплату: берём новый `redirectUrl` и заново запускаем опрос.
  Future<void> retry() async {
    if (_settled || isClosed) return;
    emit(const KaspiPaymentState.retrying());
    final url = await _service.payAgain(_orderId);
    if (isClosed) return;
    if (url == null || url.isEmpty) {
      emit(const KaspiPaymentState.failed());
      return;
    }
    emit(KaspiPaymentState.pending(url));
    _startTimers();
  }

  @override
  Future<void> close() {
    _poller?.cancel();
    _expiry?.cancel();
    return super.close();
  }
}
