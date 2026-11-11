package com.example.ceila

import flutter.overlay.window.flutter_overlay_window.OverlayMessengerRelayFix
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor,
            "ceila/overlay_bridge",
        ).setMethodCallHandler { call, result ->
            if (call.method == "restoreHostMessenger") {
                OverlayMessengerRelayFix.restore(flutterEngine.dartExecutor)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
