package com.example.bedbug.exchange

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.os.ParcelUuid
import android.util.Log
import java.util.UUID

/**
 * Découverte des téléphones BedBug autour de soi : s'annoncer, et écouter les annonces des autres.
 *
 * Une annonce BLE classique tient en 31 octets, et l'UUID de service en prend déjà une bonne partie. L'annonce ne
 * porte donc que l'UUID, sur lequel les autres filtrent leur scan. L'identifiant éphémère et le PSM (le numéro du
 * canal L2CAP, un peu comme un port réseau) vont dans la réponse au scan, que le téléphone qui scanne récupère
 * automatiquement.
 *
 * Le scan et l'annonce sont permanents, sans aucun minuteur : un minuteur Android s'arrête quand le processeur dort,
 * et un scan programmé ne démarrerait jamais écran éteint. Le scan reste donc actif en mode basse consommation, et
 * c'est la puce Bluetooth qui filtre sur l'UUID BedBug : elle ne réveille le téléphone que si elle voit un pair.
 *
 * Toutes les méthodes s'utilisent sur le thread principal.
 *
 * @param adapter adaptateur Bluetooth du téléphone.
 * @param onPeerSeen appelé à chaque annonce BedBug complète, avec l'appareil, son identifiant et son PSM.
 */
@SuppressLint("MissingPermission")
class BleDiscovery(
    private val adapter: BluetoothAdapter,
    private val onPeerSeen: (device: BluetoothDevice, peerId: ByteArray, psm: Int) -> Unit,
) {
    companion object {
        /** UUID de service BedBug, présent dans toutes les annonces de l'app. */
        val SERVICE_UUID: UUID = UUID.fromString("b3db0600-5e1f-4c2a-9d3e-6b6564627567")

        /** Taille de l'identifiant éphémère annoncé, en octets. */
        const val PEER_ID_SIZE = 4

        /** Taille du PSM annoncé, en octets. */
        private const val PSM_SIZE = 2

        /** Étiquette des journaux Android. */
        private const val TAG = "BleDiscovery"
    }

    /** Indique si la découverte tourne. */
    private var isRunning = false

    /** Callback de l'annonce en cours, nécessaire pour l'arrêter. */
    private var advertiseCallback: AdvertiseCallback? = null

    /** Callback du scan en cours, nécessaire pour l'arrêter. */
    private var scanCallback: ScanCallback? = null

    /**
     * Démarre l'annonce et le scan. Sans effet si la découverte tourne déjà.
     *
     * @param localId identifiant éphémère de ce téléphone.
     * @param psm numéro du canal L2CAP de ce téléphone.
     */
    fun start(localId: ByteArray, psm: Int) {
        if (isRunning) {
            return
        }
        isRunning = true
        startAdvertising(localId, psm)
        startScan()
    }

    /** Arrête l'annonce et le scan. La puce partage sa radio : les garder pendant un échange diviserait le débit. */
    fun stop() {
        isRunning = false
        scanCallback?.let { adapter.bluetoothLeScanner?.stopScan(it) }
        scanCallback = null
        // `bluetoothLeAdvertiser` vaut `null` si le Bluetooth vient d'être coupé : il n'y a alors plus rien à arrêter.
        advertiseCallback?.let { adapter.bluetoothLeAdvertiser?.stopAdvertising(it) }
        advertiseCallback = null
    }

    /**
     * Commence à s'annoncer.
     *
     * @param localId identifiant éphémère de ce téléphone.
     * @param psm numéro du canal L2CAP de ce téléphone.
     */
    private fun startAdvertising(localId: ByteArray, psm: Int) {
        val advertiser = adapter.bluetoothLeAdvertiser
        if (advertiser == null) {
            Log.w(TAG, "Annonce BLE indisponible")
            return
        }
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
            .setConnectable(true)
            .build()
        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceUuid(ParcelUuid(SERVICE_UUID))
            .build()
        val serviceData = localId + byteArrayOf((psm shr 8).toByte(), psm.toByte())
        val scanResponse = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceData(ParcelUuid(SERVICE_UUID), serviceData)
            .build()
        val callback = object : AdvertiseCallback() {
            override fun onStartFailure(errorCode: Int) {
                Log.w(TAG, "Annonce impossible, code $errorCode")
            }
        }
        advertiseCallback = callback
        advertiser.startAdvertising(settings, data, scanResponse, callback)
    }

    /** Lance un scan filtré sur l'UUID BedBug : sans filtre, Android coupe le scan quand l'écran s'éteint. */
    private fun startScan() {
        val scanner = adapter.bluetoothLeScanner
        if (scanner == null) {
            Log.w(TAG, "Scan BLE indisponible")
            return
        }
        val filter = ScanFilter.Builder().setServiceUuid(ParcelUuid(SERVICE_UUID)).build()
        Log.i(TAG, "Filtrage par la puce Bluetooth : ${adapter.isOffloadedFilteringSupported}")
        // Basse consommation : le scan ne s'arrête jamais, un pair est tout de même vu en quelques secondes.
        val settings = ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_POWER).build()
        val callback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                readAdvertisement(result)
            }

            override fun onScanFailed(errorCode: Int) {
                Log.w(TAG, "Scan impossible, code $errorCode")
            }
        }
        scanCallback = callback
        scanner.startScan(listOf(filter), settings, callback)
    }

    /**
     * Extrait l'identifiant et le PSM d'une annonce reçue.
     *
     * La réponse au scan arrive parfois après l'annonce : sans données de service, le résultat suivant les portera.
     *
     * @param result résultat de scan.
     */
    private fun readAdvertisement(result: ScanResult) {
        val serviceData = result.scanRecord?.getServiceData(ParcelUuid(SERVICE_UUID)) ?: return
        if (serviceData.size < PEER_ID_SIZE + PSM_SIZE) {
            return
        }
        val peerId = serviceData.copyOfRange(0, PEER_ID_SIZE)
        val highByte = serviceData[PEER_ID_SIZE].toInt() and 0xFF
        val lowByte = serviceData[PEER_ID_SIZE + 1].toInt() and 0xFF
        onPeerSeen(result.device, peerId, (highByte shl 8) or lowByte)
    }
}
