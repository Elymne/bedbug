package fr.cyneila.bedbug.domain.models

data class WifiDevice(
    val deviceId: String,
    val deviceName: String? = null,
    val groupOwner: Boolean = false,
    val address: String? = null
)
