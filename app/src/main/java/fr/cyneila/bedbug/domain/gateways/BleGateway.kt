package fr.cyneila.bedbug.domain.gateways

import fr.cyneila.bedbug.domain.models.BeaconData
import kotlinx.coroutines.flow.Flow

interface BleGateway {
    // === Broadcast functions === \\
    fun startAdvertising(payload: ByteArray)
    fun stopAdvertising()

    // Scanning functions.
    fun startScan(onBeaconDetected: (BeaconData) -> Unit)
    fun stopScan()

    // TODO : Transfert functions ? Or maybe I'll use WIFI for that.
}