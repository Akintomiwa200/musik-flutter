package com.musik.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        var eventSink: EventChannel.EventSink? = null
    }

    private val CHANNEL = "com.musik.app/notification"
    private val EVENT_CHANNEL = "com.musik.app/notification_events"

    private val actionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.getStringExtra("action") ?: return
            try {
                eventSink?.success(action)
            } catch (_: Exception) {}
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotification" -> {
                    val args = call.arguments as? Map<String, Any> ?: emptyMap()
                    val title = args["title"] as? String ?: ""
                    val artist = args["artist"] as? String ?: ""
                    val artUrl = args["artUrl"] as? String ?: ""
                    val isPlaying = args["isPlaying"] as? Boolean ?: false

                    val intent = Intent(this, MusicNotificationService::class.java).apply {
                        action = MusicNotificationService.ACTION_UPDATE
                        putExtra(MusicNotificationService.EXTRA_TITLE, title)
                        putExtra(MusicNotificationService.EXTRA_ARTIST, artist)
                        putExtra(MusicNotificationService.EXTRA_ART_URL, artUrl)
                        putExtra(MusicNotificationService.EXTRA_IS_PLAYING, isPlaying)
                    }
                    startForegroundService(intent)
                    result.success(null)
                }
                "cancelNotification" -> {
                    val intent = Intent(this, MusicNotificationService::class.java).apply {
                        action = MusicNotificationService.ACTION_CANCEL
                    }
                    startService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )

        val filter = IntentFilter("com.musik.app.NOTIFICATION_ACTION")
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(actionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(actionReceiver, filter)
        }
    }

    override fun onDestroy() {
        try { unregisterReceiver(actionReceiver) } catch (_: Exception) {}
        super.onDestroy()
    }
}
