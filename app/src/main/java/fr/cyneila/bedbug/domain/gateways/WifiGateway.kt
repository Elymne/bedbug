package fr.cyneila.bedbug.domain.gateways

interface WifiGateway {
    fun start(deviceId: ByteArray, targetDeviceId: ByteArray, callback: WifiConnectionCallback)
    fun stop()
}

interface WifiConnectionCallback {
    fun onConnected(connection: WifiConnection)
    fun onDataReceived(data: ByteArray)
    fun onError(error: Throwable)
    fun onDisconnected()
}

interface WifiConnection {
    fun send(data: ByteArray)
    fun close()
}