package com.example.bedbug.exchange

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.util.Log
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Accélère le lien radio avec un pair déjà connecté en L2CAP.
 *
 * L'API L2CAP d'Android ne permet pas de demander un intervalle de connexion court ni la PHY 2M, alors que ce sont
 * eux qui font le débit. L'astuce vient du spike de la phase 0 : ouvrir en plus une connexion GATT vers le même
 * appareil. Elle ne transporte aucune donnée, mais elle partage le même lien radio que le L2CAP : les réglages
 * demandés par GATT profitent donc aussi au L2CAP.
 */
@SuppressLint("MissingPermission")
object LinkTuner {
    /** Étiquette des journaux Android. */
    private const val TAG = "LinkTuner"

    /** Attente maximale des réglages : un pair qui ne gère pas la PHY 2M ne doit pas bloquer l'échange. */
    private const val SETUP_TIMEOUT_SECONDS = 3L

    /**
     * Demande la priorité haute et la PHY 2M, et attend la réponse. Bloquant : à appeler hors du thread principal.
     *
     * Retourne la connexion GATT, à garder ouverte pendant tout l'échange et à fermer à la fin.
     *
     * @param context contexte applicatif.
     * @param device appareil du pair.
     */
    fun tune(context: Context, device: BluetoothDevice): BluetoothGatt {
        val isTuned = CountDownLatch(1)
        val callback = object : BluetoothGattCallback() {
            override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
                if (newState != BluetoothProfile.STATE_CONNECTED) {
                    isTuned.countDown()
                    return
                }
                gatt.requestConnectionPriority(BluetoothGatt.CONNECTION_PRIORITY_HIGH)
                gatt.setPreferredPhy(
                    BluetoothDevice.PHY_LE_2M_MASK,
                    BluetoothDevice.PHY_LE_2M_MASK,
                    BluetoothDevice.PHY_OPTION_NO_PREFERRED,
                )
            }

            override fun onPhyUpdate(gatt: BluetoothGatt, txPhy: Int, rxPhy: Int, status: Int) {
                Log.i(TAG, "PHY envoi $txPhy, réception $rxPhy, statut $status")
                isTuned.countDown()
            }
        }
        val gatt = device.connectGatt(context, false, callback, BluetoothDevice.TRANSPORT_LE)
        if (!isTuned.await(SETUP_TIMEOUT_SECONDS, TimeUnit.SECONDS)) {
            Log.i(TAG, "Pas de réponse PHY sous $SETUP_TIMEOUT_SECONDS s, échange lancé quand même")
        }
        return gatt
    }
}
