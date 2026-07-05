package com.musik.app

import android.content.Intent
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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method channel for sending notification data to native
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotification" -> {
                    val args = call.arguments as? Map<String, Any>
                    val title = args?.get("title") as? String ?: ""
                    val artist = args?.get("artist") as? String ?: ""
                    val album = args?.get("album") as? String ?: ""
                    val artUrl = args?.get("artUrl") as? String ?: ""
                    val isPlaying = args?.get("isPlaying") as? Boolean ?: false

                    val intent = Intent(this, MusicNotificationService::class.java).apply {
                        action = MusicNotificationService.ACTION_UPDATE
                        putExtra(MusicNotificationService.EXTRA_TITLE, title)
                        putExtra(MusicNotificationService.EXTRA_ARTIST, artist)
                        putExtra(MusicNotificationService.EXTRA_ALBUM, album)
                        putExtra(MusicNotificationService.EXTRA_ART_URL, artUrl)
                        putExtra(MusicNotificationService.EXTRA_IS_PLAYING, isPlaying)
                    }
                    startService(intent)
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

        // Event channel for receiving notification actions
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
    }
}
