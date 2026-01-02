package fr.cyneila.bedbug.infrastructure.gateways

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.p2p.WifiP2pInfo
import android.net.wifi.p2p.WifiP2pManager
import android.util.Log
import androidx.annotation.RequiresPermission
import fr.cyneila.bedbug.domain.gateways.WifiConnectionCallback
import fr.cyneila.bedbug.domain.gateways.WifiGateway
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.net.ServerSocket
import java.net.Socket


class WifiGatewayImpl(private val context: Context) : WifiGateway {
    companion object {
        private const val TAG = "WifiGateway"
        private const val PORT = 8988
    }

    private val manager = context.getSystemService(Context.WIFI_P2P_SERVICE) as WifiP2pManager
    private val channel = manager.initialize(context, context.mainLooper, null)
    private var connectionCallback: WifiConnectionCallback? = null
    private val scope = CoroutineScope(Dispatchers.IO)

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> {
                    manager.requestConnectionInfo(channel) { info: WifiP2pInfo ->
                        if (info.groupFormed && info.isGroupOwner) {
                            startServer()
                            return@requestConnectionInfo
                        }

                        if (info.groupFormed) {
                            connectToGroupOwner(info.groupOwnerAddress.toString())
                            return@requestConnectionInfo
                        }
                    }
                }
            }
        }
    }

    /**
     * Entry point of WIFI connection.
     * The callback should allow us to manipulate data easily from Service Foreground.
     */
    @RequiresPermission(allOf = [Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.NEARBY_WIFI_DEVICES])
    override fun start(
        deviceId: ByteArray,
        targetDeviceId: ByteArray,
        callback: WifiConnectionCallback
    ) {
        this.connectionCallback = callback

        // register receiver
        val filter = IntentFilter(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
        context.registerReceiver(receiver, filter)

        // Start peer discovery
        manager.discoverPeers(channel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                Log.d(TAG, "Discovery started")
            }

            override fun onFailure(reason: Int) {
                callback.onError(Exception("Discovery failed $reason"))
            }
        })
    }

    /**
     * Try to connect as a client and not the server owner.
     * Trigger onConnected callback that will allow us to know from Service that we have make connection to something.
     */
    private fun connectToGroupOwner(hostAddress: String) {
        scope.launch {
            try {
                val socket = Socket(hostAddress, PORT)
                val connection = TcpWifiConnection(socket, scope, connectionCallback)
                connectionCallback?.onConnected(connection)
                connection.startListening()
            } catch (e: Exception) {
                connectionCallback?.onError(e)
            }
        }
    }

    /**
     * Try to create a server and let other device connect to us.
     */
    private fun startServer() {
        scope.launch {
            try {
                val serverSocket = ServerSocket(PORT)
                val socket = serverSocket.accept()
                val connection = TcpWifiConnection(socket, scope, connectionCallback)
                connectionCallback?.onConnected(connection)
                connection.startListening()
            } catch (e: Exception) {
                connectionCallback?.onError(e)
            }
        }
    }

    /**
     * Stop brutally the connection between two paired devices.
     */
    override fun stop() {
        context.unregisterReceiver(receiver)
    }
}