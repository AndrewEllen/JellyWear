package com.jellywear.jellyfin_wear_os

import android.os.Bundle
import androidx.wear.ambient.AmbientModeSupport
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity(), AmbientModeSupport.AmbientCallbackProvider {
    private val CHANNEL = "com.jellywear.jellyfin_wear_os/ongoing_activity"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AmbientModeSupport.attach(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startOngoingActivity" -> {
                    val title = call.argument<String>("title") ?: "Jellyfin Remote"
                    OngoingActivityService.start(this, title)
                    result.success(null)
                }
                "stopOngoingActivity" -> {
                    OngoingActivityService.stop(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun getAmbientCallback(): AmbientModeSupport.AmbientCallback {
        return object : AmbientModeSupport.AmbientCallback() {
            override fun onEnterAmbient(ambientDetails: Bundle?) {
                // App enters ambient mode - screen dims but app stays active
            }

            override fun onExitAmbient() {
                // App exits ambient mode - screen returns to normal
            }

            override fun onUpdateAmbient() {
                // Called periodically in ambient mode for updates
            }
        }
    }
}
