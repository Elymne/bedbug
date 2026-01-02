package fr.cyneila.bedbug.infrastructure.di

import fr.cyneila.bedbug.domain.gateways.BleGateway
import fr.cyneila.bedbug.domain.gateways.WifiGateway
import fr.cyneila.bedbug.infrastructure.gateways.BleGatewayImpl
import fr.cyneila.bedbug.infrastructure.gateways.WifiGatewayImpl
import org.koin.dsl.module

/**
 * TODO: Potentiellement séparer les modules pour :
 *  - Les usecases
 *  - Les repositories
 *  - Les gateways
 *  Histoire de simplifier tout cela.
 */
val appModule = module {
    single<BleGateway> { BleGatewayImpl(get()) }
    single<WifiGateway> { WifiGatewayImpl(get()) }
}