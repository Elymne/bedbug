package com.example.bedbug.exchange

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.IBinder
import android.util.Log
import com.example.bedbug.R

/**
 * Service de premier plan qui garde l'échange en vie quand l'app n'est plus à l'écran.
 *
 * Sans service, Android tue une app en arrière-plan au bout de quelques minutes. Un service « de premier plan » est
 * toléré parce qu'il affiche une notification permanente : l'utilisateur voit que l'app travaille, et peut l'arrêter.
 * Le type `connectedDevice` déclaré dans le manifeste indique qu'il sert à communiquer avec un appareil proche.
 *
 * Le service ne fait qu'une chose : garder le processus vivant et posséder la [ExchangeRadio]. Le protocole reste en
 * Dart, dans le moteur partagé ([SharedFlutterEngine]).
 *
 * L'arrêt est possible à tout moment, depuis la notification ou depuis les réglages de l'app. Dans les deux cas,
 * [onDestroy] ferme la radio et prévient Dart par l'événement `stopped`.
 */
class ExchangeService : Service() {
    companion object {
        /** Action de l'intent envoyé par le bouton « Arrêter » de la notification. */
        private const val ACTION_STOP = "com.example.bedbug.exchange.STOP"

        /** Identifiant du canal de notification. */
        private const val CHANNEL_ID = "exchange"

        /** Identifiant de la notification permanente. */
        private const val NOTIFICATION_ID = 1

        /** Étiquette des journaux Android. */
        private const val TAG = "ExchangeService"

        /**
         * Lance le service. Autorisé seulement quand l'app est à l'écran : Android lève sinon une exception.
         *
         * @param context contexte applicatif.
         */
        fun start(context: Context) {
            context.startForegroundService(Intent(context, ExchangeService::class.java))
        }

        /**
         * Arrête le service.
         *
         * @param context contexte applicatif.
         */
        fun stop(context: Context) {
            context.stopService(Intent(context, ExchangeService::class.java))
        }
    }

    /** Radio possédée par le service, créée au démarrage. */
    private var radio: ExchangeRadio? = null

    /** Le service n'est pas lié : tout passe par [ExchangeChannels]. */
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    /** Traite un démarrage du service, ou l'appui sur « Arrêter » dans la notification. */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        // Android exige cet appel dans les secondes qui suivent `startForegroundService`, sous peine de plantage. Il le
        // refuse parfois quand c'est lui qui relance le service en arrière-plan : on abandonne alors proprement.
        try {
            startForeground(NOTIFICATION_ID, buildNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)
        } catch (error: IllegalStateException) {
            Log.w(TAG, "Passage au premier plan refusé", error)
            stopSelf()
            return START_NOT_STICKY
        }
        if (radio == null) {
            SharedFlutterEngine.get(this)
            val newRadio = ExchangeRadio(applicationContext) { stopSelf() }
            radio = newRadio
            ExchangeChannels.radio = newRadio
            newRadio.start()
        }
        // Si Android tue le processus, il relance le service dès que possible.
        return START_STICKY
    }

    /** Ferme la radio et prévient Dart, quelle que soit la raison de l'arrêt. */
    override fun onDestroy() {
        radio?.stop()
        radio = null
        ExchangeChannels.radio = null
        ExchangeChannels.emit(mapOf("event" to "stopped"))
        super.onDestroy()
    }

    /** Retourne la notification permanente : un appui ouvre l'app, le bouton arrête le service. */
    private fun buildNotification(): Notification {
        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.exchange_notification_channel),
            NotificationManager.IMPORTANCE_LOW,
        )
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)

        val stopIntent = PendingIntent.getService(
            this,
            0,
            Intent(this, ExchangeService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE,
        )
        val stopAction = Notification.Action.Builder(null, getString(R.string.exchange_notification_stop), stopIntent)
            .build()
        val openIntent = PendingIntent.getActivity(
            this,
            0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE,
        )
        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(getString(R.string.exchange_notification_title))
            .setContentText(getString(R.string.exchange_notification_text))
            .setContentIntent(openIntent)
            .addAction(stopAction)
            .setOngoing(true)
            .build()
    }
}
