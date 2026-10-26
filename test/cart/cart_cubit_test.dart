import 'dart:async';

import 'package:bai_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_cart_repository.dart';

void main() {
  late FakeCartRepository repo;
  late CartCubit cubit;

  setUp(() {
    repo = FakeCartRepository();
    cubit = CartCubit(cartRepository: repo);
  });

  tearDown(() => cubit.close());

  group('очистка корзины (пункт 10)', () {
    test(
      'добавить A, добавить B, очистить, добавить C → в корзине только C',
      () async {
        await cubit.addCart(id: 1, product: product(1));
        await cubit.addCart(id: 2, product: product(2));
        expect(repo.serverQuantities, {1: 1, 2: 1});

        final cleared = await cubit.clearCart();
        expect(cleared, isTrue);
        expect(repo.serverQuantities, isEmpty,
            reason: 'очистка должна дойти до сервера, а не только до UI');
        expect(cubit.state, isA<CartEmpty>());

        await cubit.addCart(id: 3, product: product(3));
        await cubit.getCart();

        expect(repo.serverQuantities, {3: 1},
            reason: 'старые позиции не должны воскреснуть');
        expect(cubit.quantityOf(1), 0);
        expect(cubit.quantityOf(2), 0);
        expect(cubit.quantityOf(3), 1);
      },
    );

    test('очистка делает ровно один DELETE /cart', () async {
      await cubit.addCart(id: 1, product: product(1));
      await cubit.addCart(id: 1, product: product(1));
      await cubit.addCart(id: 2, product: product(2));
      repo.calls.clear();

      await cubit.clearCart();

      expect(repo.calls.where((c) => c == 'clearCart').length, 1);
      expect(
        repo.calls.where((c) => c.startsWith('addToCart')),
        isEmpty,
        reason: 'старая реализация слала по запросу на каждую единицу',
      );
    });

    test('на сервер никогда не уходит quantity < 1', () async {
      // FakeCartRepository бросает StateError, если такое случится.
      await cubit.addCart(id: 1, product: product(1));
      await cubit.addCart(id: 1, product: product(1));
      await cubit.removeCart(id: 1);
      await cubit.clearCart();
      expect(
        repo.calls.where((c) => c.contains(',0)') || c.contains(',-')),
        isEmpty,
      );
    });
  });

  group('epoch-гард', () {
    test('ответ GET, начатый до очистки, не воскрешает корзину', () async {
      await cubit.addCart(id: 1, product: product(1));
      await cubit.addCart(id: 2, product: product(2));

      // Запускаем медленный GET и, не дожидаясь, очищаем корзину.
      final gate = Completer<void>();
      repo.getCartDelay = () => gate.future;
      final slowGet = cubit.getCart();

      repo.getCartDelay = null;
      await cubit.clearCart();
      expect(cubit.state, isA<CartEmpty>());

      // Теперь отпускаем «застрявший» ответ со старым содержимым.
      gate.complete();
      await slowGet;

      expect(cubit.state, isA<CartEmpty>(),
          reason: 'устаревший ответ должен быть отброшен');
      expect(cubit.itemsCount, 0);
    });
  });

  group('чтение корзины', () {
    test('404 (корзины нет) — это CartEmpty, а не ошибка', () async {
      await cubit.getCart();
      expect(cubit.state, isA<CartEmpty>());
      expect(cubit.state, isNot(isA<CartGetError>()));
    });

    test('после оформления заказа корзина гаснет сразу', () async {
      await cubit.addCart(id: 1, product: product(1));
      expect(cubit.itemsCount, 1);

      await repo.clearCart(); // сервер удалил корзину вместе с заказом
      await cubit.refreshAfterOrder();

      expect(cubit.state, isA<CartEmpty>());
      expect(cubit.itemsCount, 0);
    });
  });

  group('уменьшение количества', () {
    test('с 3 до 2: удаление позиции + добавление с нужным количеством',
        () async {
      repo.seed({1: 3});
      await cubit.getCart();
      repo.calls.clear();

      await cubit.removeCart(id: 1);

      expect(repo.serverQuantities, {1: 2});
      expect(
        repo.calls.where((c) => c.startsWith('deleteCartItem')).length,
        1,
      );
      expect(repo.calls, contains('addToCart(1,2)'));
    });

    test('последняя единица удаляется одним запросом, без повторного добавления',
        () async {
      repo.seed({1: 1});
      await cubit.getCart();
      repo.calls.clear();

      await cubit.removeLine(id: 1);

      expect(repo.serverQuantities, isEmpty);
      expect(repo.calls.where((c) => c.startsWith('addToCart')), isEmpty);
      expect(cubit.state, isA<CartEmpty>());
    });

    test('провал повторного добавления сообщается, а не проглатывается',
        () async {
      repo.seed({1: 3});
      await cubit.getCart();
      // Оба вызова (основной и повтор) падают.
      repo.failNextAdds = 2;

      final events = <CartEvent>[];
      final sub = cubit.events.listen(events.add);
      await cubit.removeCart(id: 1);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(events.whereType<CartQuantityChangeFailedEvent>(), isNotEmpty);
    });
  });

  group('ошибки сервера', () {
    test('«не хватает на складе» доходит до пользователя', () async {
      repo.rejectNextAddWith = 'Not enough items in stock';

      final events = <CartEvent>[];
      final sub = cubit.events.listen(events.add);
      final ok = await cubit.addCart(id: 1, product: product(1));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(ok, isFalse);
      final rejected = events.whereType<CartWriteRejectedEvent>().toList();
      expect(rejected, isNotEmpty);
      expect(rejected.first.message, 'Not enough items in stock');
      expect(cubit.quantityOf(1), 0,
          reason: 'оптимистичное +1 должно откатиться');
    });
  });
}
