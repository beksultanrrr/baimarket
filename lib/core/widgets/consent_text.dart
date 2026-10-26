import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../app_pallete.dart';
import '../services/global_config_service.dart';

/// Текст согласия с кликабельными ссылками на оферту и политику
/// конфиденциальности — как на экране авторизации.
///
/// [text] должен содержать [offerLabel] и [privacyLabel] дословно: подписи
/// ищутся в строке как подстроки и заменяются на ссылки. Поэтому в ARB фразу
/// и метки надо править вместе, иначе ссылка просто не подсветится (текст при
/// этом останется читаемым — молча ничего не сломается).
///
/// Адреса документов приходят из `/globalConfig` и открываются во внешнем
/// браузере: внутренний WebView не годится, MinIO отдаёт PDF как
/// `binary/octet-stream`, и на Android это пустой экран.
class ConsentText extends StatefulWidget {
  const ConsentText({
    super.key,
    required this.text,
    required this.offerLabel,
    required this.privacyLabel,
    this.textStyle,
    this.linkColor = mainColorLight,
  });

  final String text;
  final String offerLabel;
  final String privacyLabel;
  final TextStyle? textStyle;
  final Color linkColor;

  @override
  State<ConsentText> createState() => _ConsentTextState();
}

class _ConsentTextState extends State<ConsentText> {
  late final TapGestureRecognizer _offerTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _offerTap = TapGestureRecognizer()..onTap = () => _openDoc(offer: true);
    _privacyTap = TapGestureRecognizer()..onTap = () => _openDoc(offer: false);
    // Греем конфиг заранее, чтобы тап открывал документ без ожидания сети.
    GlobalConfigService.load();
  }

  @override
  void dispose() {
    _offerTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  Future<void> _openDoc({required bool offer}) async {
    final l10n = AppLocalizations.of(context)!;
    final label = offer ? widget.offerLabel : widget.privacyLabel;
    final config =
        GlobalConfigService.cached ?? await GlobalConfigService.load();
    final url = offer ? config?.offerDocUrl : config?.privacyDocUrl;
    if (await openDocumentUrl(url) || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.failedToOpen(label)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.textStyle ??
        const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6E6E6E),
        );
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: base,
        children: buildConsentSpans(
          text: widget.text,
          links: {
            widget.offerLabel: _offerTap,
            widget.privacyLabel: _privacyTap,
          },
          linkStyle: base.copyWith(
            color: widget.linkColor,
            decoration: TextDecoration.underline,
            decorationColor: widget.linkColor,
          ),
        ),
      ),
    );
  }
}

/// Режет [text] на обычные куски и ссылки по ключам [links].
///
/// Совпадения ищутся слева направо, ближайшее выигрывает — так подписи могут
/// идти в строке в любом порядке и на любом языке. Если метка в тексте не
/// найдена, кусок остаётся обычным текстом.
List<InlineSpan> buildConsentSpans({
  required String text,
  required Map<String, GestureRecognizer> links,
  required TextStyle linkStyle,
}) {
  final spans = <InlineSpan>[];
  var i = 0;
  while (i < text.length) {
    var matchStart = -1;
    var matched = '';
    for (final link in links.keys) {
      if (link.isEmpty) continue;
      final idx = text.indexOf(link, i);
      if (idx != -1 && (matchStart == -1 || idx < matchStart)) {
        matchStart = idx;
        matched = link;
      }
    }
    if (matchStart == -1) {
      spans.add(TextSpan(text: text.substring(i)));
      break;
    }
    if (matchStart > i) {
      spans.add(TextSpan(text: text.substring(i, matchStart)));
    }
    spans.add(
      TextSpan(text: matched, style: linkStyle, recognizer: links[matched]),
    );
    i = matchStart + matched.length;
  }
  return spans;
}
