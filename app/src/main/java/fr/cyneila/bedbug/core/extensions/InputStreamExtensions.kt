package fr.cyneila.bedbug.core.extensions

import java.io.EOFException
import java.io.IOException
import java.io.InputStream

@Throws(IOException::class)
fun InputStream.readExactly(size: Int): ByteArray {
    val buffer = ByteArray(size)
    var offset = 0

    while (offset < size) {
        val read = this.read(buffer, offset, size - offset)
        if (read == -1) {
            throw EOFException("Stream fermé avant lecture complète")
        }
        offset += read
    }

    return buffer
}