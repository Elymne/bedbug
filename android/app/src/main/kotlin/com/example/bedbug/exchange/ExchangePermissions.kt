package com.example.bedbug.exchange

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build

/** Permissions Android sans lesquelles l'échange ne peut pas fonctionner. */
object ExchangePermissions {
    /**
     * Retourne les permissions indispensables à ce téléphone.
     *
     * Android 12 a créé des permissions Bluetooth dédiées. Avant, le scan BLE exige la localisation précise, et que
     * la localisation soit activée dans les réglages du téléphone, sans quoi le scan ne remonte rien.
     */
    fun required(): List<String> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return listOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_ADVERTISE,
                Manifest.permission.BLUETOOTH_CONNECT,
            )
        }
        return listOf(Manifest.permission.ACCESS_FINE_LOCATION)
    }

    /**
     * Indique si toutes les permissions indispensables sont accordées.
     *
     * @param context contexte quelconque.
     */
    fun areGranted(context: Context): Boolean {
        return required().all { context.checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED }
    }
}
