package fr.cyneila.bedbug.core.usecases

sealed class Result<out T>

data class Success<T>(val value: T) : Result<T>()

data class Failure(val error: Exception) : Result<Nothing>()

inline fun <T> Result<T>.onSuccess(block: (T) -> Unit): Result<T> {
    if (this is Success) block(value)
    return this
}

inline fun <T> Result<T>.onFailure(block: (Failure) -> Unit): Result<T> {
    if (this is Failure) block(this)
    return this
}