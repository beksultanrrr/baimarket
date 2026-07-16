part of 'kaspi_payment_cubit.dart';

enum KaspiStatus { pending, retrying, paid, failed, expired }

class KaspiPaymentState extends Equatable {
  final KaspiStatus status;

  /// Актуальная ссылка Kaspi (для QR и кнопки «Оплатить»).
  /// Непустая только в состоянии `pending`.
  final String? redirectUrl;

  const KaspiPaymentState._(this.status, [this.redirectUrl]);

  const KaspiPaymentState.pending(String url)
      : this._(KaspiStatus.pending, url);
  const KaspiPaymentState.retrying() : this._(KaspiStatus.retrying);
  const KaspiPaymentState.paid() : this._(KaspiStatus.paid);
  const KaspiPaymentState.failed() : this._(KaspiStatus.failed);
  const KaspiPaymentState.expired() : this._(KaspiStatus.expired);

  @override
  List<Object?> get props => [status, redirectUrl];
}
