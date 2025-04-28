package com.example.tobuy

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Bundle

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.tobuy/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openAddItem") {
                // Naviguer vers AddItemScreen
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
                MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                    .invokeMethod("openAddItem", null)
            }
        }
    }
}
