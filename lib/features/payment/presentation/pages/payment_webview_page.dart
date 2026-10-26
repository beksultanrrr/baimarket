import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/app_pallete.dart';
import '../../../../core/services/app_logger.dart';
import '../../data/models/payment_args.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';
import '../../../order_success/data/models/order_success_args.dart';

class PaymentWebViewPage extends StatefulWidget {
  final PaymentArgs args;

  const PaymentWebViewPage({super.key, required this.args});

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  bool _isLoading = true;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    paymentLog.step(
      'WebView init',
      'url="${widget.args.paymentUrl}", '
          'amount=${widget.args.amount}, '
          'brand=${widget.args.cardBrand?.name}',
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final allowedHosts = [
              'api.iris-cosmetics.kz',
              'minio.iris-cosmetics.kz',
              'pay.kaspi.kz',
              'epay.kkb.kz',
              'securepay.kkb.kz',
              '3ds.kkb.kz',
            ];
            final uri = Uri.tryParse(request.url);
            final allow = uri != null && uri.scheme == 'https' &&
                (allowedHosts.any((h) => uri.host.endsWith(h)) ||
                    uri.scheme == 'https');
            paymentLog.event(
              'WebView nav request',
              '${allow ? 'ALLOW' : 'BLOCK'} ${request.url}',
            );
            if (uri != null && uri.scheme == 'https') {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
          onPageStarted: (url) =>
              paymentLog.event('WebView page started', url),
          onPageFinished: (url) {
            paymentLog.event('WebView page finished', url);
            setState(() => _isLoading = false);
          },
          onWebResourceError: (err) =>
              paymentLog.warn('WebView error', err.description),
        ),
      )
      ..loadRequest(Uri.parse(widget.args.paymentUrl ?? ''));
  }

  void _onPaidPressed() {
    final a = widget.args;
    paymentLog.step('user confirmed payment', 'orderRedirect=${a.paymentUrl}');
    final successArgs = OrderSuccessArgs(
      orderId: DateTime.now().millisecondsSinceEpoch.remainder(1000000),
      itemsTotal: a.itemsTotal ?? a.amount,
      oldTotal: a.oldTotal,
      savings: a.savings ?? 0,
      ticketsEarned: a.ticketsEarned ?? 0,
      deliveryAddressLine: a.deliveryAddressLine,
      deliveryPostalCode: a.deliveryPostalCode,
      productImageUrls: a.productImageUrls,
      cardBrand: a.cardBrand,
    );
    paymentLog.nav('push /order_success', 'orderId=${successArgs.orderId}');
    liveAwarePush(context, '/order_success', extra: successArgs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Оплата картой',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        actions: [
          CupertinoButton(
            child: const Text(
              'Далее',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: mainColorLight,
              ),
            ),
            onPressed: () => _showExitConfirmationDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.white,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Идёт оплата...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmationDialog(BuildContext context) {
    if (Platform.isAndroid) {
      _showAndroidExitDialog(context);
    } else if (Platform.isIOS) {
      _showIOSExitDialog(context);
    }
  }

  void _showAndroidExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Завершить покупку'),
          content: const Text('Вы оплатили?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _onPaidPressed();
              },
              child: const Text('Далее'),
            ),
          ],
        );
      },
    );
  }

  void _showIOSExitDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Завершить покупку'),
          content: const Text('Вы оплатили?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              isDefaultAction: true,
              child: const Text('Отмена'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
                _onPaidPressed();
              },
              isDestructiveAction: true,
              child: const Text('Далее'),
            ),
          ],
        );
      },
    );
  }
}
