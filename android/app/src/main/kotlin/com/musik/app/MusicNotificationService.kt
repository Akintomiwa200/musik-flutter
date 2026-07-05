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
import java.net.URL

class MusicNotificationService : Service() {

    companion object {
        const val CHANNEL_ID = "musik_playback"
        const val NOTIFICATION_ID = 1001

        const val ACTION_PLAY = "com.musik.app.PLAY"
        const val ACTION_PAUSE = "com.musik.app.PAUSE"
        const val ACTION_NEXT = "com.musik.app.NEXT"
        const val ACTION_PREV = "com.musik.app.PREV"
        const val ACTION_STOP = "com.musik.app.STOP"
        const val ACTION_UPDATE = "com.musik.app.UPDATE"
        const val ACTION_CANCEL = "com.musik.app.CANCEL"

        const val EXTRA_TITLE = "title"
        const val EXTRA_ARTIST = "artist"
        const val EXTRA_ALBUM = "album"
        const val EXTRA_ART_URL = "artUrl"
        const val EXTRA_IS_PLAYING = "isPlaying"

        private var _artBitmap: Bitmap? = null
        private var _currentTitle = ""
        private var _currentArtist = ""
        private var _currentIsPlaying = false
        private var _currentArtUrl = ""

        fun setArtBitmap(bitmap: Bitmap?) {
            _artBitmap = bitmap
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PLAY -> sendEventToFlutter("play")
            ACTION_PAUSE -> sendEventToFlutter("pause")
            ACTION_NEXT -> sendEventToFlutter("next")
            ACTION_PREV -> sendEventToFlutter("prev")
            ACTION_STOP -> {
                sendEventToFlutter("stop")
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
            ACTION_CANCEL -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
            ACTION_UPDATE -> {
                _currentTitle = intent?.getStringExtra(EXTRA_TITLE) ?: _currentTitle
                _currentArtist = intent?.getStringExtra(EXTRA_ARTIST) ?: _currentArtist
                _currentIsPlaying = intent?.getBooleanExtra(EXTRA_IS_PLAYING, false) ?: _currentIsPlaying
                val artUrl = intent?.getStringExtra(EXTRA_ART_URL) ?: _currentArtUrl
                if (artUrl.isNotEmpty() && artUrl != _currentArtUrl) {
                    _currentArtUrl = artUrl
                    loadArtBitmap(artUrl)
                }
                val notification = buildNotification(_currentTitle, _currentArtist, _currentIsPlaying)
                startForeground(NOTIFICATION_ID, notification)
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
            lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
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

        val playPauseAction = if (isPlaying) {
            NotificationCompat.Action(
                android.R.drawable.ic_media_pause, "Pause",
                actionIntent(ACTION_PAUSE)
            )
        } else {
            NotificationCompat.Action(
                android.R.drawable.ic_media_play, "Play",
                actionIntent(ACTION_PLAY)
            )
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(artist)
            .setSubText("Musik")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setLargeIcon(_artBitmap)
            .setContentIntent(openPendingIntent)
            .setOngoing(isPlaying)
            .setShowWhen(false)
            .setStyle(
                androidx.media.app.NotificationCompat.MediaStyle()
                    .setShowActionsInCompactView(0, 1, 2)
            )
            .addAction(android.R.drawable.ic_media_previous, "Previous", actionIntent(ACTION_PREV))
            .addAction(playPauseAction)
            .addAction(android.R.drawable.ic_media_next, "Next", actionIntent(ACTION_NEXT))
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            .build()
    }

    private fun actionIntent(action: String): PendingIntent {
        val intent = Intent(this, MusicNotificationService::class.java).apply {
            this.action = action
        }
        return PendingIntent.getService(
            this, action.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun sendEventToFlutter(event: String) {
        try {
            MainActivity.eventSink?.success(event)
        } catch (_: Exception) {}
    }

    private fun loadArtBitmap(artUrl: String) {
        Thread {
            try {
                val url = URL(artUrl)
                val connection = url.openConnection()
                connection.connectTimeout = 5000
                connection.readTimeout = 5000
                val input = connection.getInputStream()
                val bitmap = BitmapFactory.decodeStream(input)
                input.close()
                _artBitmap = bitmap
                // Rebuild notification with art
                val notification = buildNotification(_currentTitle, _currentArtist, _currentIsPlaying)
                val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                manager.notify(NOTIFICATION_ID, notification)
            } catch (_: Exception) {}
        }.start()
    }
}
