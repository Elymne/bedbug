package fr.cyneila.bedbug.core.extensions

import android.view.View
import android.view.animation.Animation
import android.view.animation.CycleInterpolator
import android.view.animation.TranslateAnimation

/**
 * Simple Shaky Animation that can be applied to any view type.
 */
fun View.addShakyAnim(duration: Long, force: Float) {
    this.animate().cancel()
    this.clearAnimation()

    val shakeAnim =
        TranslateAnimation(-1f * force, 1f * force, -1f * 0.25f * force, 1f * 0.25f * force)
    shakeAnim.duration = duration
    shakeAnim.interpolator = CycleInterpolator(5f)
    shakeAnim.repeatCount = Animation.INFINITE
    this.startAnimation(shakeAnim)
}

fun View.stopAnim() {
    this.animate().cancel()
    this.clearAnimation()
}