package fr.cyneila.bedbug.core.usecases

abstract class Usecase<P, D> {
    abstract suspend fun run(params: P): Result<D>
}

abstract class UsecaseNoParams<D> {
    abstract suspend fun run(): Result<D>
}