package com.example.bedbug.exchange

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.util.Log
import java.io.IOException
import java.security.SecureRandom
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

/**
 * Chef d'orchestre de la radio : relie la découverte, le serveur L2CAP et les connexions.
 *
 * Cycle de vie d'une rencontre :
 * 1. Le téléphone ouvre un serveur L2CAP, puis s'annonce et scanne.
 * 2. Deux téléphones se voient. Seul celui dont l'identifiant est le plus petit se connecte, pour ne pas ouvrir deux
 *    connexions croisées.
 * 3. Les deux coupent annonce et scan : le débit passe d'environ 16 à 31 Ko/s (mesures de la phase 0).
 * 4. Dart reçoit `connected` et déroule `ExchangeSession`. Kotlin ne connaît rien au protocole : il transporte des
 *    octets.
 * 5. À la fermeture, la découverte reprend.
 *
 * Un seul échange à la fois : la bande passante est rare, et un second échange ralentirait les deux.
 *
 * @param context contexte applicatif.
 * @param onFailure appelé si la radio ne peut plus fonctionner, par exemple quand le Bluetooth est coupé.
 */
@SuppressLint("MissingPermission")
class ExchangeRadio(private val context: Context, private val onFailure: () -> Unit) {
    private companion object {
        /** Étiquette des journaux Android. */
        const val TAG = "ExchangeRadio"

        /** Délai avant de recontacter un pair après un échange : il n'y a plus rien de neuf à court terme. */
        const val COOLDOWN_MILLIS = 10 * 60 * 1000L

        /** Délai avant de recontacter un pair après une tentative, tant que sa réussite n'est pas confirmée. */
        const val RETRY_MILLIS = 30 * 1000L

        /** Durée de vie de l'identifiant éphémère : un observateur ne peut pas suivre un téléphone dans la durée. */
        const val ID_ROTATION_MILLIS = 15 * 60 * 1000L

        /** Durée maximale du maintien du processeur, marge comprise au-delà de la durée maximale d'une session. */
        const val WAKE_LOCK_TIMEOUT_MILLIS = 2 * 60 * 1000L
    }

    /** Adaptateur Bluetooth du téléphone, `null` s'il n'en a pas. */
    private val adapter = context.getSystemService(BluetoothManager::class.java)?.adapter

    /** File du thread principal, sur lequel Android attend les opérations de découverte. */
    private val mainHandler = Handler(Looper.getMainLooper())

    /** Empêche le processeur de s'endormir pendant un échange, écran éteint. */
    private val wakeLock = context.getSystemService(PowerManager::class.java)
        .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "bedbug:exchange")
        .apply { setReferenceCounted(false) }

    /** Identifiant éphémère de ce téléphone, remplacé toutes les [ID_ROTATION_MILLIS]. */
    @Volatile
    private var localId = newLocalId()

    /** Remplace l'identifiant éphémère et programme le remplacement suivant. */
    private val idRotation = object : Runnable {
        override fun run() {
            localId = newLocalId()
            // Pendant un échange, la découverte est coupée : elle reprendra d'elle-même avec le nouvel identifiant.
            if (!isBusy.get()) {
                discovery?.stop()
                discovery?.start(localId, psm)
            }
            mainHandler.postDelayed(this, ID_ROTATION_MILLIS)
        }
    }

    /** Prochain instant où chaque pair peut être recontacté. */
    private val nextAttemptAt = ConcurrentHashMap<String, Long>()

    /** Fin du délai déjà signalée à Dart pour chaque pair : un pair vu sans cesse n'est noté qu'une fois par délai. */
    private val reportedDelays = ConcurrentHashMap<String, Long>()

    /** Compteur des identifiants de connexion. */
    private val nextConnectionId = AtomicInteger(0)

    /** Indique si la radio tourne. */
    private val isRunning = AtomicBoolean(false)

    /** Indique si un échange occupe la radio, de la tentative de connexion à la fermeture. */
    private val isBusy = AtomicBoolean(false)

    /** Découverte, `null` tant que la radio n'a pas démarré. */
    private var discovery: BleDiscovery? = null

    /** Serveur L2CAP en attente de connexions entrantes. */
    private var serverSocket: BluetoothServerSocket? = null

    /** Numéro du canal L2CAP, réannoncé à chaque reprise de la découverte. */
    private var psm = 0

    /** Socket en cours de connexion : le fermer interrompt un `connect` bloqué. */
    @Volatile
    private var connectingSocket: BluetoothSocket? = null

    /** Connexion de l'échange en cours. */
    @Volatile
    private var activeConnection: PeerConnection? = null

    /** Démarre le serveur L2CAP et la découverte. Sans effet si la radio tourne déjà. */
    fun start() {
        val bluetooth = adapter
        if (bluetooth == null || !isRunning.compareAndSet(false, true)) {
            return
        }
        val server = try {
            bluetooth.listenUsingInsecureL2capChannel()
        } catch (error: IOException) {
            Log.w(TAG, "Serveur L2CAP impossible", error)
            isRunning.set(false)
            onFailure()
            return
        }
        serverSocket = server
        psm = server.psm
        Thread { acceptConnections(server) }.start()

        discovery = BleDiscovery(bluetooth, ::onPeerSeen).also { it.start(localId, psm) }
        mainHandler.postDelayed(idRotation, ID_ROTATION_MILLIS)
    }

    /** Arrête tout, y compris l'échange en cours. À appeler sur le thread principal. */
    fun stop() {
        if (!isRunning.compareAndSet(true, false)) {
            return
        }
        mainHandler.removeCallbacks(idRotation)
        discovery?.stop()
        // Fermer le serveur débloque le `accept` en attente, ce qui termine son thread.
        runCatching { serverSocket?.close() }
        serverSocket = null
        runCatching { connectingSocket?.close() }
        activeConnection?.close()
        nextAttemptAt.clear()
        reportedDelays.clear()
    }

    /**
     * Retourne la connexion d'identifiant [id], ou `null` si elle est fermée.
     *
     * @param id identifiant de la connexion.
     */
    fun connection(id: Int): PeerConnection? {
        return activeConnection?.takeIf { it.id == id }
    }

    /**
     * Note que l'échange de la connexion [id] a réussi : le pair peut attendre avant d'être recontacté.
     *
     * Avant cette confirmation, seul le délai court s'applique : un échange coupé en route sera vite retenté.
     *
     * @param id identifiant de la connexion.
     */
    fun confirmSuccess(id: Int) {
        val peerHex = connection(id)?.peerHex ?: return
        nextAttemptAt[peerHex] = SystemClock.elapsedRealtime() + COOLDOWN_MILLIS
    }

    /**
     * Accepte les connexions entrantes tant que la radio tourne.
     *
     * @param server serveur L2CAP.
     */
    private fun acceptConnections(server: BluetoothServerSocket) {
        while (isRunning.get()) {
            val client = try {
                server.accept()
            } catch (error: IOException) {
                // Une exception alors que la radio devrait tourner : le Bluetooth a été coupé.
                if (isRunning.get()) {
                    Log.w(TAG, "Serveur L2CAP interrompu", error)
                    mainHandler.post(onFailure)
                }
                return
            }
            if (!beginExchange()) {
                runCatching { client.close() }
                continue
            }
            open(client, null, null)
        }
    }

    /**
     * Traite un pair vu par la découverte : lance la connexion si ce téléphone doit être l'initiateur.
     *
     * @param device appareil du pair.
     * @param peerId identifiant éphémère du pair.
     * @param peerPsm numéro du canal L2CAP du pair.
     */
    private fun onPeerSeen(device: BluetoothDevice, peerId: ByteArray, peerPsm: Int) {
        val now = SystemClock.elapsedRealtime()
        val peerHex = peerId.joinToString("") { "%02x".format(it) }
        if (compareUnsigned(localId, peerId) >= 0) {
            return
        }
        val nextAttempt = nextAttemptAt[peerHex] ?: 0L
        if (now < nextAttempt) {
            reportDelayedPeer(device, peerHex, nextAttempt, now)
            return
        }
        if (!beginExchange()) {
            return
        }
        nextAttemptAt.values.removeAll { it <= now }
        reportedDelays.keys.retainAll(nextAttemptAt.keys)
        nextAttemptAt[peerHex] = now + RETRY_MILLIS
        Thread { connect(device, peerPsm, peerHex) }.start()
    }

    /**
     * Signale à Dart un pair ignoré à cause du délai, une seule fois par délai.
     *
     * Le court délai entre deux tentatives n'est pas signalé : il remplirait le journal sans rien apprendre.
     *
     * @param device appareil du pair.
     * @param peerHex identifiant du pair.
     * @param nextAttempt fin du délai.
     * @param now instant présent.
     */
    private fun reportDelayedPeer(device: BluetoothDevice, peerHex: String, nextAttempt: Long, now: Long) {
        if (nextAttempt - now <= RETRY_MILLIS || reportedDelays[peerHex] == nextAttempt) {
            return
        }
        reportedDelays[peerHex] = nextAttempt
        ExchangeChannels.emit(mapOf("event" to "peerDelayed", "peer" to device.address))
    }

    /**
     * Côté initiateur : se connecte au pair et règle le lien. Bloquant : tourne sur son propre thread.
     *
     * @param device appareil du pair.
     * @param peerPsm numéro du canal L2CAP du pair.
     * @param peerHex identifiant du pair, confié à la connexion.
     */
    private fun connect(device: BluetoothDevice, peerPsm: Int, peerHex: String) {
        val socket = try {
            device.createInsecureL2capChannel(peerPsm)
        } catch (error: IOException) {
            Log.w(TAG, "Canal L2CAP impossible", error)
            reportConnectionFailure(device)
            endExchange()
            return
        }
        connectingSocket = socket
        try {
            socket.connect()
            val gatt = LinkTuner.tune(context, device)
            open(socket, gatt, peerHex)
        } catch (error: IOException) {
            Log.w(TAG, "Connexion L2CAP impossible", error)
            runCatching { socket.close() }
            reportConnectionFailure(device)
            endExchange()
        } finally {
            connectingSocket = null
        }
    }

    /**
     * Signale à Dart une connexion impossible. Un arrêt de la radio n'en est pas une : il ferme lui-même le socket.
     *
     * @param device appareil du pair.
     */
    private fun reportConnectionFailure(device: BluetoothDevice) {
        if (isRunning.get()) {
            ExchangeChannels.emit(mapOf("event" to "connectionFailed", "peer" to device.address))
        }
    }

    /**
     * Confie un socket connecté à Dart, ou le ferme si la radio s'est arrêtée entre-temps.
     *
     * @param socket socket L2CAP connecté.
     * @param gatt connexion de réglage du lien, `null` côté répondant.
     * @param peerHex identifiant du pair, `null` côté répondant.
     */
    private fun open(socket: BluetoothSocket, gatt: BluetoothGatt?, peerHex: String?) {
        val connection = PeerConnection(nextConnectionId.incrementAndGet(), socket, gatt, peerHex) { closed ->
            activeConnection = null
            ExchangeChannels.emit(mapOf("event" to "closed", "id" to closed.id))
            endExchange()
        }
        if (!isRunning.get() || !ExchangeChannels.hasListener) {
            connection.close()
            return
        }
        activeConnection = connection
        ExchangeChannels.emit(
            mapOf(
                "event" to "connected",
                "id" to connection.id,
                "peer" to socket.remoteDevice.address,
                "isInitiator" to (peerHex != null),
            ),
        )
        connection.startReading()
    }

    /** Retourne un nouvel identifiant éphémère. */
    private fun newLocalId(): ByteArray {
        return ByteArray(BleDiscovery.PEER_ID_SIZE).also { SecureRandom().nextBytes(it) }
    }

    /** Réserve la radio pour un échange et coupe la découverte. Retourne `false` si elle est déjà occupée. */
    private fun beginExchange(): Boolean {
        if (!isBusy.compareAndSet(false, true)) {
            return false
        }
        // Dès la réservation : écran éteint, le processeur se rendormirait pendant la connexion.
        wakeLock.acquire(WAKE_LOCK_TIMEOUT_MILLIS)
        mainHandler.post { discovery?.stop() }
        return true
    }

    /** Libère la radio et relance la découverte. */
    private fun endExchange() {
        if (wakeLock.isHeld) {
            wakeLock.release()
        }
        isBusy.set(false)
        mainHandler.post {
            if (isRunning.get()) {
                discovery?.start(localId, psm)
            }
        }
    }

    /**
     * Compare deux identifiants octet par octet, comme des entiers non signés.
     *
     * Retourne un nombre négatif si [left] est plus petit, positif s'il est plus grand, `0` s'ils sont égaux.
     *
     * @param left premier identifiant.
     * @param right second identifiant, de même taille.
     */
    private fun compareUnsigned(left: ByteArray, right: ByteArray): Int {
        for (index in left.indices) {
            val difference = (left[index].toInt() and 0xFF) - (right[index].toInt() and 0xFF)
            if (difference != 0) {
                return difference
            }
        }
        return 0
    }
}
