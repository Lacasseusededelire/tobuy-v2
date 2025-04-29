package com.example.tobuy

import android.app.PictureInPictureParams
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Bundle
import android.util.Log

class MainActivity : FlutterActivity() {
    private val WIDGET_CHANNEL = "com.example.tobuy/widget"
    private val PIP_CHANNEL = "com.example.tobuy/pip"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Canal pour le widget
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openAddItem") {
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setClassName(context, "com.example.tobuy.MainActivity")
                    putExtra("route", "/add-item")
                }
                startActivity(intent)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
        // Canal pour PiP
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL).setMethodCallHandler { call, result ->
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
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        intent?.let {
            if (it.getStringExtra("action") == "openAddItem") {
                MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
                    .invokeMethod("openAddItem", null)
            }
        }
    }

    private fun enterPipMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(9, 16)) // Ratio 9:16 pour mobile
                .build()
            try {
                enterPictureInPictureMode(params)
                Log.d("MainActivity", "Mode PiP activé")
            } catch (e: Exception) {
                Log.e("MainActivity", "Erreur PiP: ${e.message}")
            }
        } else {
            Log.w("MainActivity", "PiP non supporté sur cette version d'Android")
        }
    }
}