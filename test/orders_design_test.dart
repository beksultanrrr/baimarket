import 'package:bai_market/core/app_pallete.dart';
import 'package:bai_market/features/orders/data/models/order_model.dart';
import 'package:bai_market/features/orders/presentation/widgets/order_card.dart';
import 'package:bai_market/features/orders/presentation/widgets/order_filter.dart';
import 'package:bai_market/features/orders/presentation/widgets/order_status_tag.dart';
import 'package:bai_market/features/orders/presentation/widgets/orders_empty_state.dart';
import 'package:bai_market/features/orders/presentation/widgets/orders_filter_tabs.dart';
import 'package:bai_market/features/orders/presentation/widgets/payment_status_chip.dart';
import 'package:bai_market/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Цвета экрана «Мои заказы» заданы макетом и согласованы с палитрой:
/// статус-тег — пастельная заливка + насыщенный текст, активный чип фильтра —
/// чёрный. Тест держит эти значения, чтобы правка «на глаз» их не сдвинула.
/// Минимальный заказ: карточке от модели нужны только статус, id, сумма и
/// адрес — товаров нет, чтобы тест не трогал сеть.
OrderModel _order() => OrderModel(
      id: 342345,
      userId: 1,
      trackingNumber: null,
      paymentUrl: null,
      paymentTypeSlug: 'kaspi',
      paymentFailureReason: null,
      paymentId: null,
      cartItems: const [],
      deliveryInfo: const {
        'deliveryAddress': 'Алматы, Бостандыкский район',
        'postalCode': '1201023',
      },
      createdAt: '2026-07-14T08:18:07.000Z',
      totalPrice: 46793,
      deliveryPrice: 0,
      status: 'WAY',
    );

void main() {
  Widget wrap(Widget child) => MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      );

  BoxDecoration decorationOf(WidgetTester tester, Finder container) =>
      tester.widget<Container>(container).decoration! as BoxDecoration;

  group('статус-тег заказа', () {
    // status → (фон, цвет текста) из макета.
    final cases = <String, (Color, Color)>{
      'WAY': (accentSoftGreen, mainColorDark),
      'DELIVERED': (accentSoftPink, Color(0xFFFF2C61)),
      'CANCELED': (Color(0xFFE8DFFE), Color(0xFF7654C7)),
    };

    cases.forEach((status, colors) {
      testWidgets('$status — пастельный фон и цветной текст', (tester) async {
        await tester.pumpWidget(wrap(OrderStatusTag(status: status)));

        final box = decorationOf(tester, find.byType(Container));
        expect(box.color, colors.$1, reason: 'фон тега');

        final label = tester.widget<Text>(find.byType(Text));
        expect(label.style?.color, colors.$2, reason: 'цвет текста тега');

        // Пилюля, а не скруглённый прямоугольник.
        final radius = (box.borderRadius! as BorderRadius).topLeft.x;
        expect(radius, greaterThanOrEqualTo(50));
      });
    });
  });

  testWidgets('карточка заказа — рамка #00000012 шириной 1.5', (tester) async {
    await tester.pumpWidget(
      wrap(OrderCard(order: _order(), onTap: () {})),
    );

    final card = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(OrderCard),
            matching: find.byType(Container),
          )
          .first,
    );
    final side = ((card.decoration! as BoxDecoration).border! as Border).top;
    expect(side.color, hairlineBorder);
    expect(side.width, kHairlineWidth);
  });

  testWidgets('чип «Оплачен» — та же рамка, без заливки', (tester) async {
    await tester.pumpWidget(
      wrap(const PaymentStatusChip(isPaid: true, price: 46793)),
    );

    final box = decorationOf(tester, find.byType(Container));
    expect(box.color, isNull, reason: 'заливки у чипа нет');
    final side = (box.border! as Border).top;
    expect(side.color, hairlineBorder);
    expect(side.width, kHairlineWidth);
  });

  testWidgets('пустое состояние — типографика по макету', (tester) async {
    await tester.pumpWidget(wrap(OrdersEmptyState(onGoShopping: () {})));

    final title = tester.widget<Text>(find.text('Нет заказов')).style!;
    expect(title.fontSize, 20);
    expect(title.fontWeight, FontWeight.w500);

    final subtitle =
        tester.widget<Text>(find.text('Заказы будут отображаться тут')).style!;
    expect(subtitle.fontSize, 14);
    expect(subtitle.fontWeight, FontWeight.w400);
    expect(subtitle.color, const Color(0x66000000), reason: '#00000066');

    final button = tester.widget<Text>(find.text('К покупкам')).style!;
    expect(button.fontSize, 20);
    expect(button.fontWeight, FontWeight.w600);
    expect(button.color, Colors.white);

    // Плашка кнопки — чёрная, как в макете.
    final box = decorationOf(
      tester,
      find
          .ancestor(
            of: find.text('К покупкам'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(box.color, darkButtonColor);
  });

  group('чипы фильтров', () {
    testWidgets('выбранный — чёрный с белым текстом', (tester) async {
      await tester.pumpWidget(
        wrap(OrdersFilterTabs(selected: OrderFilter.all, onSelected: (_) {})),
      );

      final selected = find.ancestor(
        of: find.text('Все'),
        matching: find.byType(AnimatedContainer),
      );
      final box =
          tester.widget<AnimatedContainer>(selected).decoration! as BoxDecoration;
      expect(box.color, darkButtonColor, reason: 'фон выбранного чипа');
      expect(
        tester.widget<Text>(find.text('Все')).style?.color,
        Colors.white,
      );
    });

    testWidgets('невыбранный — белый с тёмным текстом', (tester) async {
      await tester.pumpWidget(
        wrap(OrdersFilterTabs(selected: OrderFilter.all, onSelected: (_) {})),
      );

      final other = find.ancestor(
        of: find.text('Активные'),
        matching: find.byType(AnimatedContainer),
      );
      final box =
          tester.widget<AnimatedContainer>(other).decoration! as BoxDecoration;
      expect(box.color, Colors.white);
      expect(
        tester.widget<Text>(find.text('Активные')).style?.color,
        darkButtonColor,
        reason: 'в макете текст тёмный, а не серый',
      );
    });
  });
}
