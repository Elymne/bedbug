package fr.cyneila.bedbug.infrastructure.gateways

import androidx.annotation.RequiresPermission
import fr.cyneila.bedbug.domain.gateways.BleGateway
import fr.cyneila.bedbug.domain.models.BeaconData
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.Manifest
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.ParcelUuid
import android.util.Log

class BleGatewayImpl(context: Context) : BleGateway {
    companion object {
        private val STREET_PATH_UUID: ParcelUuid =
            ParcelUuid.fromString("1a2805ba-fa11-4679-b892-bedb39d12111") // 16bytes.
        private const val MANUFACTURER_ID: Int = 0x0bed
        private const val TAG = "BleGateway"

        // Static settings for now. Quicker as I cycling broadcasting.
        private val SETTINGS = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
            .setConnectable(false)
            .build()
    }

    private val bluetoothManager =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val bluetoothAdapter = bluetoothManager.adapter

    private val advertiser: BluetoothLeAdvertiser? = bluetoothAdapter?.bluetoothLeAdvertiser
    private val scanner: BluetoothLeScanner? = bluetoothAdapter?.bluetoothLeScanner

    private var advertiseCallback: AdvertiseCallback? = null
    private var scanCallback: ScanCallback? = null

    /**
     * TODO : Devrait retourner une valeur en cas d'erreur
     */
    @RequiresPermission(Manifest.permission.BLUETOOTH_ADVERTISE)
    override fun startAdvertising(payload: ByteArray) {
        if (advertiseCallback != null) {
            Log.d(TAG, "Advertiser : Already running")
            return
        }

        if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) {
            Log.d(TAG, "Advertiser : BLE adapter not enabled")
            return
        }

        if (!bluetoothAdapter.isMultipleAdvertisementSupported) {
            Log.e(TAG, "BLE advertising not supported")
            return
        }

        if(advertiser == null) {
            Log.e(TAG, "BLE advertiser not activated")
            return
        }

        val advertiseData = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceUuid(STREET_PATH_UUID)
            .addManufacturerData(MANUFACTURER_ID, payload)
            .build()

        val callback = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
                Log.i(TAG, "Advertising started")
            }

            override fun onStartFailure(errorCode: Int) {
                Log.e(TAG, "Advertising failed: $errorCode")
            }
        }
        advertiseCallback = callback
        advertiser.startAdvertising(SETTINGS, advertiseData, callback)
    }

    @RequiresPermission(Manifest.permission.BLUETOOTH_ADVERTISE)
    override fun stopAdvertising() {
        advertiseCallback?.let {
            advertiser?.stopAdvertising(it)
            advertiseCallback = null
        }
    }

    @RequiresPermission(Manifest.permission.BLUETOOTH_SCAN)
    override fun startScan(onBeaconDetected: (BeaconData) -> Unit) {
        if (scanCallback != null) {
            Log.d(TAG, "Scanner : Already running")
            return
        }

        if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled || scanner == null) {
            Log.d(TAG, "Scanner : BLE adapter not enabled")
            return
        }

        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                // If data doesn't contain any services : skip.
                if (result.scanRecord == null) return

                // If data doesn't contain my service : skip.
                val hasService =
                    result.scanRecord!!.serviceUuids?.any { it.uuid == STREET_PATH_UUID.uuid }
                if (hasService == null || !hasService) return

                // And now, get the payload.
                val payload =
                    result.scanRecord!!.getManufacturerSpecificData(MANUFACTURER_ID) ?: return
                // Send full beacon data.
                onBeaconDetected(
                    BeaconData(
                        deviceId = result.device.address,
                        rssi = result.rssi,
                        payload = payload
                    )
                )
            }

            override fun onScanFailed(errorCode: Int) {
                Log.e(TAG, "Scan failed: $errorCode")
            }
        }
        scanner.startScan(null, settings, scanCallback)
    }

    @RequiresPermission(Manifest.permission.BLUETOOTH_SCAN)
    override fun stopScan() {
        scanCallback?.let {
            scanner?.stopScan(it)
            scanCallback = null
        }
    }
}