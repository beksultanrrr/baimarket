import 'package:bai_market/core/app_pallete.dart';
import 'package:bai_market/core/widgets/main_button.dart';
import 'package:bai_market/features/my_data/presentation/widgets/add_photo_bottom_sheet.dart';
import 'package:bai_market/features/my_data/presentation/widgets/base_avatar_tile.dart';
import 'package:bai_market/features/my_data/presentation/widgets/delete_account_text_button.dart';
import 'package:bai_market/features/my_data/presentation/widgets/photo_avatar_tile.dart';
import 'package:bai_market/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Экран «Мои данные» свёрстан по Frame 19: плитки 80×80 со скруглением 15,
/// кнопки высотой 60, заливка полей #000000 3%, рамки #000000 7%.
void main() {
  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  BoxDecoration decoOf(WidgetTester tester, Finder f) =>
      tester.widget<Container>(f).decoration! as BoxDecoration;

  testWidgets('главная кнопка — чёрная, 60pt, радиус 15', (tester) async {
    await tester.pumpWidget(
      wrap(MainButton(onPressed: () {}, text: 'Сохранить')),
    );

    final box = decoOf(tester, find.byType(Container).first);
    expect(box.color, darkButtonColor);
    expect((box.borderRadius! as BorderRadius).topLeft.x, 15);
    expect(tester.getSize(find.byType(Container).first).height, 60);
  });

  testWidgets('на экранах адресов та же кнопка — зелёная', (tester) async {
    await tester.pumpWidget(
      wrap(
        MainButton(
          onPressed: () {},
          text: 'Добавить еще адрес',
          color: mainColorLight,
        ),
      ),
    );

    expect(decoOf(tester, find.byType(Container).first).color, mainColorLight);
  });

  testWidgets('«Удалить аккаунт» — рамка без заливки, 60pt', (tester) async {
    await tester.pumpWidget(
      wrap(DeleteAccountTextButton(text: 'Удалить аккаунт', onPressed: () {})),
    );

    final container = find
        .descendant(
          of: find.byType(DeleteAccountTextButton),
          matching: find.byType(Container),
        )
        .first;
    final box = decoOf(tester, container);
    expect(box.color, isNull, reason: 'заливки нет');
    expect((box.border! as Border).top.color, hairlineBorder);
    expect((box.border! as Border).top.width, kHairlineWidth);
    expect(tester.getSize(container).height, 60);
  });

  testWidgets('плитка «Базовый» — 80×80, зелёная, без обводки',
      (tester) async {
    await tester.pumpWidget(wrap(const BaseAvatarTile(initial: 'G')));

    final container = find
        .descendant(
          of: find.byType(BaseAvatarTile),
          matching: find.byType(Container),
        )
        .first;
    final box = decoOf(tester, container);
    expect(box.color, accentSoftGreen);
    expect(box.border, isNull, reason: 'в макете обводки нет');
    expect((box.borderRadius! as BorderRadius).topLeft.x, 15);
    expect(tester.getSize(container), const Size(80, 80));
  });

  testWidgets('шит «Добавить фото» — пункты с рамкой, текст 16/w500 #00000080',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AddPhotoBottomSheet(onSourceSelected: (_) {}),
        ),
      ),
    );

    for (final label in ['Галлерея', 'Камера']) {
      final style = tester.widget<Text>(find.text(label)).style!;
      expect(style.fontSize, 16, reason: '$label: кегль');
      expect(style.fontWeight, FontWeight.w500, reason: '$label: насыщенность');
      expect(style.color, const Color(0x80000000), reason: '$label: #00000080');

      final box = decoOf(
        tester,
        find
            .ancestor(of: find.text(label), matching: find.byType(Container))
            .first,
      );
      expect(box.color, isNull, reason: '$label: заливки нет');
      expect((box.border! as Border).top.color, hairlineBorder);
      expect((box.border! as Border).top.width, kHairlineWidth);
    }
  });

  testWidgets('плитка «Выбрать» — 80×80, заливка 3% и рамка 7%',
      (tester) async {
    await tester.pumpWidget(wrap(const PhotoAvatarTile(imageUrl: '')));

    final container = find
        .descendant(
          of: find.byType(PhotoAvatarTile),
          matching: find.byType(Container),
        )
        .first;
    final box = decoOf(tester, container);
    expect(box.color, fieldFill);
    expect((box.border! as Border).top.color, hairlineBorder);
    expect(tester.getSize(container), const Size(80, 80));
  });
}
