package com.bmarket.baimarket

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.provider.Telephony
import android.os.Build
import android.os.Bundle

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.bai_market/sms"
    private var smsReceiver: BroadcastReceiver? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createDefaultNotificationChannel()
    }

    /**
     * Канал уведомлений создаётся здесь, а не только из Dart.
     *
     * Причина: канал из Dart появляется лишь после AwesomeNotifications().initialize(),
     * а FCM SDK может принять сообщение в процессе, где Dart ещё не стартовал.
     * Тогда Android откатывается на автоканал "Разное", который на части
     * прошивок замьючен — отсюда симптом «иногда ничего, иногда беззвучно».
     *
     * onCreate гарантированно раньше Dart, а сообщение может прийти только на
     * токен, то есть после первого запуска приложения. createNotificationChannel
     * идемпотентен.
     *
     * ВАЖНО: параметры обязаны совпадать с lib/core/push/push_channels.dart —
     * importance фиксируется при первом создании и потом не меняется.
     */
    private fun createDefaultNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            "default_channel",
            "Основные уведомления",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Канал для основных уведомлений приложения"
            enableLights(true)
            lightColor = Color.parseColor("#71CD32")
            enableVibration(true)
            setShowBadge(true)
        }
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSmsCode") {
                registerSmsReceiver()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun registerSmsReceiver() {
        if (smsReceiver == null) {
            smsReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
                        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
                        for (sms in messages) {
                            val messageBody = sms.messageBody
                            // Extract OTP code from message (assuming format: "Your code is: 1234")
                            val codeRegex = "\\b\\d{4}\\b".toRegex()
                            val matchResult = codeRegex.find(messageBody)
                            if (matchResult != null) {
                                val code = matchResult.value
                                MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                                    .invokeMethod("onSmsReceived", code)
                                break
                            }
                        }
                    }
                }
            }

            val filter = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
            registerReceiver(smsReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        smsReceiver?.let {
            unregisterReceiver(it)
            smsReceiver = null
        }
    }
}
