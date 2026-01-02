package fr.cyneila.bedbug.domain.models

data class BeaconData(
    val deviceId: String,
    val rssi: Int,
    val timestamp: Long = System.currentTimeMillis(),
    val payload: ByteArray
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as BeaconData

        if (rssi != other.rssi) return false
        if (timestamp != other.timestamp) return false
        if (deviceId != other.deviceId) return false
        if (!payload.contentEquals(other.payload)) return false

        return true
    }

    override fun hashCode(): Int {
        var result = rssi
        result = 31 * result + timestamp.hashCode()
        result = 31 * result + deviceId.hashCode()
        result = 31 * result + (payload?.contentHashCode() ?: 0)
        return result
    }
}
