package fr.cyneila.bedbug.infrastructure.gateways

import fr.cyneila.bedbug.domain.gateways.WifiConnection
import fr.cyneila.bedbug.domain.gateways.WifiConnectionCallback
import java.io.InputStream
import java.io.OutputStream
import java.net.Socket
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

class TcpWifiConnection(
    private val socket: Socket,
    private val scope: CoroutineScope,
    private val callback: WifiConnectionCallback?
) : WifiConnection {
    private val output: OutputStream = socket.getOutputStream()
    private val input: InputStream = socket.getInputStream()

    override fun send(data: ByteArray) {
        scope.launch {
            try {
                output.write(data)
                output.flush()
            } catch (e: Exception) {
                callback?.onError(e)
            }
        }
    }

    override fun close() {
        try {
            socket.close()
        } catch (_: Exception) {
        }
    }

    fun startListening() {
        Thread {
            try {
                val buffer = ByteArray(1024)
                var read: Int
                while (socket.isConnected) {
                    read = input.read(buffer)
                    if (read > 0) {
                        val data = buffer.copyOf(read)
                        callback?.onDataReceived(data)
                    }
                }
            } catch (e: Exception) {
                callback?.onError(e)
            } finally {
                callback?.onDisconnected()
                close()
            }
        }
            .start()
    }
}
