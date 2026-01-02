package fr.cyneila.bedbug.application.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log
import fr.cyneila.bedbug.domain.gateways.BleGateway
import fr.cyneila.bedbug.domain.gateways.WifiConnection
import fr.cyneila.bedbug.domain.gateways.WifiConnectionCallback
import fr.cyneila.bedbug.domain.gateways.WifiGateway
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import org.koin.android.ext.android.inject
import kotlin.random.Random

class BugPathService : Service() {
    companion object {
        private const val CHANNEL_ID = "bug_path_service"
        private const val CHANNEL_NAME = "BugPath Service"
        private const val TAG = "BugPathService"
    }

    private val bleGateway: BleGateway by inject()
    private val wifiGateway: WifiGateway by inject()

    private var advertiseJob: Job? = null
    private lateinit var payload: ByteArray
    private val discoveredDevices = mutableListOf<String>()

    @androidx.annotation.RequiresPermission(allOf = [android.Manifest.permission.ACCESS_FINE_LOCATION, android.Manifest.permission.NEARBY_WIFI_DEVICES])
    override fun onCreate() {
        super.onCreate()
        // Start foreground service + notification.
        startService()

        // Start BLE scanning + managing detected devices by sending sharable contents.
        bleGateway.startScan { beacon ->
            // If device have already been detected, we skipping.
            if (discoveredDevices.any { it == beacon.deviceId }) return@startScan
            // TODO : do a reclycler every 20mins or 30mins by clearing data inside this array. I'll manage.
            discoveredDevices.add(beacon.deviceId)

            // TODO: Try WIFI connection to send data.
            wifiGateway.start(payload, beacon.payload, object : WifiConnectionCallback {
                override fun onConnected(connection: WifiConnection) {
                    TODO("Not yet implemented")
                    // TODO : Share contents (for now, just push simple data).
                }

                override fun onDataReceived(data: ByteArray) {
                    TODO("Not yet implemented")
                    // TODO : Fetch contents.
                }

                override fun onError(error: Throwable) {
                    Log.e(TAG, "WIFI error detected, message: ${error.message}")
                }

                override fun onDisconnected() {
                    Log.d(TAG, "WIFI connection closed")
                }
            })
        }

        // Should be an option depending of app state or user's settings. Now it's just a balanced cycling mode.
        val onDurationMs = 2000L
        val offDurationMs = 8000L
        // Generate a payload that I will use like an ID.
        payload = Random.nextBytes(6)
        // Cycling with BLE broadcasting.
        advertiseJob?.cancel() // Just in case.
        advertiseJob = CoroutineScope(Dispatchers.Default).launch {
            while (isActive) {
                bleGateway.startAdvertising(payload)
                delay(onDurationMs)
                bleGateway.stopAdvertising()
                delay(offDurationMs)
            }
        }
    }

    override fun onDestroy() {
        advertiseJob?.cancel() // Important to close this firstly.
        bleGateway.stopAdvertising()
        bleGateway.stopScan()
        wifiGateway.stop()
        super.onDestroy()
    }

    private fun startService() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_LOW
        )

        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)

        val notification: Notification = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("Service BugPath actif")
            .setContentText("Le service tourne en arrière-plan")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .build()

        startForeground(1, notification)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}