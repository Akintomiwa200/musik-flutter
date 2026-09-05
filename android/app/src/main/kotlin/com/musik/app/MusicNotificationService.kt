package com.musik.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import java.net.HttpURLConnection
import java.net.URL

class MusicNotificationService : Service() {

    companion object {
        const val CHANNEL_ID = "musik_playback"
        const val NOTIFICATION_ID = 1001

        const val ACTION_UPDATE = "com.musik.app.UPDATE"
        const val ACTION_CANCEL = "com.musik.app.CANCEL"

        const val EXTRA_TITLE = "title"
        const val EXTRA_ARTIST = "artist"
        const val EXTRA_IS_PLAYING = "isPlaying"
        const val EXTRA_ART_URL = "artUrl"
    }

    private var _artBitmap: Bitmap? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_UPDATE -> {
                val title = intent.getStringExtra(EXTRA_TITLE) ?: ""
                val artist = intent.getStringExtra(EXTRA_ARTIST) ?: ""
                val isPlaying = intent.getBooleanExtra(EXTRA_IS_PLAYING, false)
                val artUrl = intent.getStringExtra(EXTRA_ART_URL) ?: ""

                if (artUrl.isNotEmpty()) loadArtBitmap(artUrl)

                val notification = buildNotification(title, artist, isPlaying)
                startForeground(NOTIFICATION_ID, notification)
            }
            ACTION_CANCEL -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Music Playback",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Shows current playing track"
            setShowBadge(false)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
        }
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(title: String, artist: String, isPlaying: Boolean): Notification {
        val openIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPendingIntent = PendingIntent.getActivity(
            this, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val playPauseIcon = if (isPlaying) android.R.drawable.ic_media_pause
                            else android.R.drawable.ic_media_play

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(artist)
            .setSubText("Musik")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setLargeIcon(_artBitmap)
            .setContentIntent(openPendingIntent)
            .setOngoing(isPlaying)
            .setShowWhen(false)
            .addAction(android.R.drawable.ic_media_previous, "Prev", actionIntent("prev"))
            .addAction(playPauseIcon, if (isPlaying) "Pause" else "Play", actionIntent(if (isPlaying) "pause" else "play"))
            .addAction(android.R.drawable.ic_media_next, "Next", actionIntent("next"))
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText(artist)
                    .setBigContentTitle(title)
            )
            .build()
    }

    private fun actionIntent(action: String): PendingIntent {
        val intent = Intent("com.musik.app.NOTIFICATION_ACTION").apply {
            setPackage(packageName)
            putExtra("action", action)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getBroadcast(this, action.hashCode(), intent, flags)
    }

    private fun loadArtBitmap(artUrl: String) {
        Thread {
            try {
                val url = URL(artUrl)
                val conn = url.openConnection() as HttpURLConnection
                conn.connectTimeout = 5000
                conn.readTimeout = 5000
                conn.connect()
                val input = conn.inputStream
                _artBitmap = BitmapFactory.decodeStream(input)
                input.close()
            } catch (_: Exception) {}
        }.start()
    }
}
