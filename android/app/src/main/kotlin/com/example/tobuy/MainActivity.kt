package com.example.tobuy

import android.os.Bundle
import android.app.PictureInPictureParams
import android.util.Rational
import android.graphics.Rect
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.tobuy/pip"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "enterPipMode") {
                enterPipMode()
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Activer l'entrée automatique en mode PiP pour Android 12+
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            setPictureInPictureParams(
                PictureInPictureParams.Builder()
                    .setAutoEnterEnabled(true)
                    .setSourceRectHint(Rect(0, 0, 100, 100)) // Ajuster selon l'UI
                    .setAspectRatio(Rational(16, 9))
                    .build()
            )
        }
    }

    private fun enterPipMode() {
        val params = PictureInPictureParams.Builder()
            .setAspectRatio(Rational(16, 9))
            .setSourceRectHint(Rect(0, 0, 100, 100)) // Ajuster selon l'UI
            .build()
        enterPictureInPictureMode(params)
    }
}