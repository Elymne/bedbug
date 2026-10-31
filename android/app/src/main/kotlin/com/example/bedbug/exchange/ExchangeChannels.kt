package com.example.bedbug.exchange

import android.bluetooth.BluetoothManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

/**
 * Pont entre le code Dart et la radio : tout ce qui traverse la frontière Kotlin/Dart passe ici.
 *
 * Deux canaux, un par sens :
 * - `bedbug/exchange` (MethodChannel, Dart appelle Kotlin) : `start`, `stop`, `send`, `confirm`, `close` ;
 * - `bedbug/exchange/events` (EventChannel, Kotlin prévient Dart) : `connected`, `data`, `closed`, `stopped`.
 *
 * Flutter impose d'utiliser ces canaux depuis le thread principal, alors que les sockets vivent sur leurs propres
 * threads : tout passe donc par [mainHandler]. Les événements sont postés dans l'ordre, si bien que Dart reçoit
 * toujours `connected`, puis les `data`, puis `closed`.
 */
object ExchangeChannels {
    /** Nom du canal des appels Dart vers Kotlin. */
    private const val METHOD_CHANNEL = "bedbug/exchange"

    /** Nom du canal des événements Kotlin vers Dart. */
    private const val EVENT_CHANNEL = "bedbug/exchange/events"

    /** Étiquette des journaux Android. */
    private const val TAG = "ExchangeChannels"

    /** File du thread principal. */
    private val mainHandler = Handler(Looper.getMainLooper())

    /** Destination des événements, `null` tant que Dart n'écoute pas. */
    @Volatile
    private var eventSink: EventChannel.EventSink? = null

    /** Radio en service, `null` quand le service d'échange est arrêté. */
    @Volatile
    var radio: ExchangeRadio? = null

    /** Vrai si Dart écoute les événements : sans lui, une connexion ne servirait à rien. */
    val hasListener: Boolean
        get() = eventSink != null

    /**
     * Branche les deux canaux sur [engine].
     *
     * @param engine moteur Flutter partagé.
     * @param context contexte applicatif, pour lancer le service.
     */
    fun attach(engine: FlutterEngine, context: Context) {
        val messenger = engine.dartExecutor.binaryMessenger
        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> result.success(start(context))
                "stop" -> {
                    ExchangeService.stop(context)
                    result.success(null)
                }
                "send" -> send(call, result)
                "confirm" -> {
                    radio?.confirmSuccess(call.argument<Int>("id")!!)
                    result.success(null)
                }
                "close" -> {
                    radio?.connection(call.argument<Int>("id")!!)?.close()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    /**
     * Envoie un événement à Dart, depuis n'importe quel thread.
     *
     * @param event contenu de l'événement.
     */
    fun emit(event: Map<String, Any>) {
        mainHandler.post { eventSink?.success(event) }
    }

    /**
     * Lance le service d'échange si le Bluetooth est utilisable, et retourne le statut attendu par Dart.
     *
     * Android peut refuser de lancer un service de premier plan, par exemple si l'app n'est plus à l'écran : c'est
     * alors un échec normal, pas un plantage.
     *
     * @param context contexte applicatif.
     */
    private fun start(context: Context): String {
        // Déjà lancé : Android a relancé le service, Dart vient simplement s'y raccorder.
        if (radio != null) {
            return "started"
        }
        if (!ExchangePermissions.areGranted(context)) {
            return "permissionDenied"
        }
        val adapter = context.getSystemService(BluetoothManager::class.java)?.adapter ?: return "unavailable"
        if (!adapter.isEnabled) {
            return "bluetoothOff"
        }
        if (adapter.bluetoothLeAdvertiser == null) {
            return "unavailable"
        }
        return try {
            ExchangeService.start(context)
            "started"
        } catch (error: IllegalStateException) {
            Log.w(TAG, "Service d'échange refusé par Android", error)
            "unavailable"
        }
    }

    /**
     * Écrit des octets sur une connexion, et ne répond à Dart qu'une fois qu'ils sont partis.
     *
     * Cette réponse tardive est la contre-pression du protocole : `ExchangeSession` attend chaque envoi avant le
     * suivant, donc la vitesse d'envoi suit celle de la radio.
     *
     * @param call appel Dart, avec `id` (connexion) et `bytes` (octets).
     * @param result réponse à renvoyer à Dart.
     */
    private fun send(call: MethodCall, result: MethodChannel.Result) {
        val connection = radio?.connection(call.argument<Int>("id")!!)
        if (connection == null) {
            result.error("closed", "connexion fermée", null)
            return
        }
        connection.send(call.argument<ByteArray>("bytes")!!) { error: IOException? ->
            mainHandler.post {
                if (error == null) {
                    result.success(null)
                    return@post
                }
                result.error("closed", error.message, null)
            }
        }
    }
}
