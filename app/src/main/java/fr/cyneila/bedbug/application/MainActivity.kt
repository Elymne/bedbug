package fr.cyneila.bedbug.application

import android.os.Build
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import fr.cyneila.bedbug.R

/**
 *  Entry point of my Apps.
 *  I'm Re-Learning Kotlin + Android dev.
 *
 *  Copyright 2025 Sacha Djurdjevic
 *  Licensed under the Apache License, Version 2.0
 */
class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Start quick logo Splashscreen for newer devices (v31+).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            installSplashScreen()
        }

        // Start Main Activity.
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Remove top bar.
        this.supportActionBar?.hide()
    }
}