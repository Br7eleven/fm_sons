package com.example.fm_sons

import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onResume() {
        super.onResume()
        requestHighRefreshRate()
    }

    private fun requestHighRefreshRate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+: pick the display mode with the highest refresh rate
            val display = display ?: return
            val highestMode = display.supportedModes.maxByOrNull { it.refreshRate } ?: return
            window.attributes = window.attributes.apply {
                preferredDisplayModeId = highestMode.modeId
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Android 6–10: set preferred refresh rate
            @Suppress("DEPRECATION")
            val display = windowManager.defaultDisplay
            val highestRate = display.supportedModes.maxByOrNull { it.refreshRate }?.refreshRate ?: return
            window.attributes = window.attributes.apply {
                @Suppress("DEPRECATION")
                preferredRefreshRate = highestRate
            }
        }
    }
}
