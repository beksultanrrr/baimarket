import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/firebase_service.dart';
import '../../../../core/push/push_channels.dart';
import '../../../../core/push/push_token_sync.dart';

/// Диагностика пушей.
///
/// Отвечает на вопросы, на которые приложение иначе ответить не может: есть ли
/// токен, дошёл ли он до сервера и с каким кодом, разрешены ли уведомления.
/// Открывается долгим нажатием на пункт «Уведомления» в профиле.
///
/// Показывает FCM-токен и в release-сборке — это осознанно, диагностировать
/// нужно именно тот билд, что стоит у тестировщика. Токен авторизации здесь
/// никогда не печатается, только факт его наличия.
class PushDebugPage extends StatefulWidget {
  const PushDebugPage({super.key});

  @override
  State<PushDebugPage> createState() => _PushDebugPageState();
}

class _PushDebugPageState extends State<PushDebugPage> {
  Map<String, String> _info = const {};
  bool _loading = true;
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final info = await PushTokenSync.diagnostics();
    final allowed = await FirebaseMessagingService.isAllowed();
    if (!mounted) return;
    setState(() {
      _info = info;
      _allowed = allowed;
      _loading = false;
    });
  }

  Future<void> _resend() async {
    await PushTokenSync.ensureRegistered(
      trigger: PushSyncTrigger.manual,
      force: true,
    );
    await _load();
  }

  Future<void> _showLocal() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 424242,
        channelKey: kDefaultChannelId,
        title: 'Тестовое уведомление',
        body: 'Если вы это видите — канал и разрешение в порядке',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Диагностика пушей')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    _allowed
                        ? 'Уведомления разрешены'
                        : 'Уведомления запрещены — пуши не появятся',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _allowed ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final entry in _info.entries)
                    _Row(label: entry.key, value: entry.value),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _showLocal,
                    child: const Text('Показать тестовое уведомление'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _resend,
                    child: const Text('Отправить токен на сервер снова'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: FirebaseMessagingService.openSystemSettings,
                    child: const Text('Системные настройки уведомлений'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Скопировано')),
              );
            },
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
