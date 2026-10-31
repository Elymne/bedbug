package com.example.bedbug.exchange

import android.annotation.SuppressLint
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothSocket
import java.io.IOException
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Une connexion L2CAP ouverte avec un pair, le temps d'un échange.
 *
 * Lire et écrire sur un socket sont des opérations bloquantes, et les deux appareils envoient en même temps : chaque
 * sens a donc son propre thread. Si la lecture et l'écriture partageaient le même, chacun attendrait que l'autre ait
 * fini d'envoyer avant de lire, et l'échange se figerait.
 *
 * @param id identifiant de la connexion, partagé avec Dart.
 * @param socket socket L2CAP connecté.
 * @param gatt connexion de réglage du lien, à fermer avec le socket, `null` côté répondant.
 * @param peerHex identifiant du pair, pour le délai avant de le recontacter, `null` côté répondant.
 * @param onClosed appelé une seule fois, à la fermeture.
 */
@SuppressLint("MissingPermission")
class PeerConnection(
    val id: Int,
    private val socket: BluetoothSocket,
    private val gatt: BluetoothGatt?,
    val peerHex: String?,
    private val onClosed: (PeerConnection) -> Unit,
) {
    private companion object {
        /** Taille du tampon de lecture, en octets. */
        const val READ_BUFFER_SIZE = 4 * 1024
    }

    /** Thread d'écriture : une seule écriture à la fois, dans l'ordre des envois. */
    private val writer = Executors.newSingleThreadExecutor()

    /** Vrai une fois la connexion fermée. */
    private val isClosed = AtomicBoolean(false)

    /**
     * Lance le thread de lecture, qui transmet les octets reçus à Dart jusqu'à la fin de la connexion.
     *
     * `read` bloque jusqu'à recevoir des octets, et retourne `-1` ou lève une exception quand la connexion se ferme.
     */
    fun startReading() {
        Thread {
            val buffer = ByteArray(READ_BUFFER_SIZE)
            try {
                val input = socket.inputStream
                while (true) {
                    val count = input.read(buffer)
                    if (count < 0) {
                        break
                    }
                    ExchangeChannels.emit(mapOf("event" to "data", "id" to id, "bytes" to buffer.copyOf(count)))
                }
            } catch (_: IOException) {
                // Connexion coupée : c'est la fin normale de ce thread.
            }
            close()
        }.start()
    }

    /**
     * Écrit [bytes] sur le thread d'écriture.
     *
     * L'écriture L2CAP bloque tant que le pair n'a pas accordé de crédits : [onDone] n'est appelé qu'une fois les
     * octets acceptés par la radio.
     *
     * @param bytes octets à envoyer.
     * @param onDone appelé à la fin, avec l'erreur s'il y en a une.
     */
    fun send(bytes: ByteArray, onDone: (IOException?) -> Unit) {
        try {
            writer.execute {
                try {
                    socket.outputStream.write(bytes)
                    onDone(null)
                } catch (error: IOException) {
                    onDone(error)
                }
            }
        } catch (_: RejectedExecutionException) {
            onDone(IOException("connexion fermée"))
        }
    }

    /**
     * Ferme la connexion. Sans effet si elle l'est déjà.
     *
     * Fermer le socket débloque les threads de lecture et d'écriture, qui s'arrêtent d'eux-mêmes.
     */
    fun close() {
        if (!isClosed.compareAndSet(false, true)) {
            return
        }
        runCatching { socket.close() }
        gatt?.disconnect()
        gatt?.close()
        writer.shutdown()
        onClosed(this)
    }
}
