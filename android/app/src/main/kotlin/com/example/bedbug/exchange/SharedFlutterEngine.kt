package com.example.bedbug.exchange

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * Unique moteur Flutter du processus, partagé entre l'écran et le service d'échange.
 *
 * Un moteur Flutter fait tourner le code Dart. Par défaut, `FlutterActivity` crée le sien et le détruit quand l'écran
 * se ferme : l'échange en arrière-plan s'arrêterait avec lui. Un second moteur pour le service ne convient pas non
 * plus : deux moteurs, ce sont deux isolates Dart qui ouvrent les mêmes fichiers Hive, ce qui peut les corrompre.
 *
 * Le moteur est donc créé une seule fois et gardé dans `FlutterEngineCache`, qui le maintient en vie tant que le
 * processus existe. Quand l'utilisateur ferme l'app, seul l'affichage s'arrête : le code Dart continue de tourner, et
 * la session d'échange avec lui. Quand il la rouvre, `MainActivity` se rattache au même moteur.
 */
object SharedFlutterEngine {
    /** Clé du moteur dans `FlutterEngineCache`. */
    private const val ENGINE_ID = "bedbug"

    /**
     * Retourne le moteur partagé, en le créant et en lançant `main()` s'il n'existe pas encore.
     *
     * À appeler depuis le thread principal, comme toute création de moteur Flutter.
     *
     * @param context contexte quelconque : seul le contexte applicatif est conservé, pour ne jamais retenir une
     *   activité fermée.
     */
    fun get(context: Context): FlutterEngine {
        val cache = FlutterEngineCache.getInstance()
        cache.get(ENGINE_ID)?.let { return it }

        val applicationContext = context.applicationContext
        val engine = FlutterEngine(applicationContext)
        // Avant `main()` : le code Dart peut utiliser les canaux dès ses premières lignes.
        ExchangeChannels.attach(engine, applicationContext)
        engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        cache.put(ENGINE_ID, engine)
        return engine
    }
}
