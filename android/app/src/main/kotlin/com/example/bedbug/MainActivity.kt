package com.example.bedbug

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import com.example.bedbug.exchange.ExchangePermissions
import com.example.bedbug.exchange.SharedFlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Activité unique de l'app : elle affiche Flutter, en se rattachant au moteur partagé.
 *
 * Les permissions se demandent depuis une activité : c'est la seule partie de l'échange qui vit ici.
 */
class MainActivity : FlutterActivity() {
    private companion object {
        /** Canal de la demande de permissions. */
        const val PERMISSIONS_CHANNEL = "bedbug/exchange/permissions"

        /** Code de la demande de permissions, pour reconnaître sa réponse. */
        const val PERMISSIONS_REQUEST_CODE = 4242
    }

    /** Réponse Dart en attente du résultat de la demande de permissions. */
    private var pendingPermissionResult: MethodChannel.Result? = null

    /** Utilise le moteur partagé plutôt que d'en créer un qui mourrait avec l'écran. */
    override fun provideFlutterEngine(context: Context): FlutterEngine {
        return SharedFlutterEngine.get(context)
    }

    /** Le moteur survit à l'écran : le service d'échange en a encore besoin. */
    override fun shouldDestroyEngineWithHost(): Boolean {
        return false
    }

    /** Branche le canal de permissions. Appelé à chaque création de l'écran, avec le même moteur. */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "request") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            requestExchangePermissions(result)
        }
    }

    /** Répond à Dart `true` si toutes les permissions indispensables sont accordées. */
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != PERMISSIONS_REQUEST_CODE) {
            return
        }
        pendingPermissionResult?.success(ExchangePermissions.areGranted(this))
        pendingPermissionResult = null
    }

    /**
     * Demande les permissions manquantes, et répond à Dart une fois que l'utilisateur a choisi.
     *
     * La notification est demandée en même temps, sans être indispensable : refusée, le service tourne quand même,
     * sa notification n'étant simplement pas affichée.
     *
     * @param result réponse à renvoyer à Dart.
     */
    private fun requestExchangePermissions(result: MethodChannel.Result) {
        val requested = ExchangePermissions.required().toMutableList()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requested.add(Manifest.permission.POST_NOTIFICATIONS)
        }
        val missing = requested.filter { checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED }
        if (missing.isEmpty()) {
            result.success(true)
            return
        }
        pendingPermissionResult = result
        requestPermissions(missing.toTypedArray(), PERMISSIONS_REQUEST_CODE)
    }
}
