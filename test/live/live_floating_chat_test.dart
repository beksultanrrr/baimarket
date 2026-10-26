import 'package:bai_market/features/live/data/models/live_chat_message_model.dart';
import 'package:bai_market/features/live/presentation/widgets/live_floating_chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Лента чата эфира: раньше это была `Column` из трёх последних сообщений —
/// историю нельзя было проскроллить. Теперь список прокручивается.
LiveChatMessageModel _msg(int i) => LiveChatMessageModel(
      id: i,
      streamId: 1,
      userId: i,
      message: 'сообщение $i',
      fullName: 'Автор $i',
      avatarUrl: null,
      isDeleted: false,
    );

void main() {
  Widget harness(List<LiveChatMessageModel> messages, {double height = 200}) =>
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: SizedBox(
            height: height,
            child: LiveFloatingChat(messages: messages),
          ),
        ),
      );

  testWidgets('лента прокручивается к старым сообщениям', (tester) async {
    final messages = List.generate(20, _msg);
    await tester.pumpWidget(harness(messages));
    await tester.pump();

    // reverse-список: снизу самое свежее, оно видно сразу.
    expect(find.text('сообщение 19'), findsOneWidget);
    expect(find.text('сообщение 0'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('сообщение 0'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(find.text('сообщение 0'), findsOneWidget, reason: 'история доступна');
    expect(tester.takeException(), isNull);
  });

  testWidgets('новое сообщение видно без ручного скролла', (tester) async {
    final messages = List.generate(10, _msg);
    await tester.pumpWidget(harness(messages));
    await tester.pump();

    await tester.pumpWidget(harness([...messages, _msg(99)]));
    await tester.pump();

    expect(find.text('сообщение 99'), findsOneWidget);
  });

  testWidgets('верхний край растворяется — есть градиентная маска',
      (tester) async {
    await tester.pumpWidget(harness(List.generate(20, _msg)));
    await tester.pump();

    expect(find.byType(ShaderMask), findsOneWidget);
  });

  testWidgets('новое сообщение всплывает, старые не переанимируются',
      (tester) async {
    final messages = List.generate(5, _msg);
    await tester.pumpWidget(harness(messages));
    await tester.pumpAndSettle();

    // Первый кадр после добавления: новое ещё прозрачное, старые — нет.
    await tester.pumpWidget(harness([...messages, _msg(99)]));
    await tester.pump();

    double opacityOf(String text) {
      final fade = tester.widgetList<FadeTransition>(
        find.ancestor(
          of: find.text(text),
          matching: find.byType(FadeTransition),
        ),
      );
      return fade.isEmpty ? 1.0 : fade.first.opacity.value;
    }

    expect(opacityOf('сообщение 99'), lessThan(1.0), reason: 'новое всплывает');
    expect(opacityOf('сообщение 4'), 1.0, reason: 'старое уже показано');

    await tester.pumpAndSettle();
    expect(opacityOf('сообщение 99'), 1.0, reason: 'анимация доигрывает');
  });

  testWidgets('чтение истории не сбивается новым сообщением', (tester) async {
    final messages = List.generate(30, _msg);
    await tester.pumpWidget(harness(messages));
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable);
    await tester.drag(scrollable, const Offset(0, 300));
    await tester.pumpAndSettle();
    final offsetBefore = tester.widget<Scrollable>(scrollable).controller!.offset;

    await tester.pumpWidget(harness([...messages, _msg(99)]));
    await tester.pumpAndSettle();

    final offsetAfter = tester.widget<Scrollable>(scrollable).controller!.offset;
    expect(offsetAfter, offsetBefore, reason: 'позиция чтения сохранена');
  });

  testWidgets('пустой чат ничего не рисует', (tester) async {
    await tester.pumpWidget(harness(const []));
    await tester.pump();

    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('показывает больше трёх сообщений, если высота позволяет',
      (tester) async {
    await tester.pumpWidget(harness(List.generate(6, _msg), height: 400));
    await tester.pump();

    // Старая вёрстка жёстко обрезала до трёх последних.
    expect(find.text('сообщение 5'), findsOneWidget);
    expect(find.text('сообщение 1'), findsOneWidget);
  });
}
