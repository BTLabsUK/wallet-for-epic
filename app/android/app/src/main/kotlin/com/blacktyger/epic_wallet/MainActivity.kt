package com.blacktyger.epic_wallet

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity, because the biometric prompt (local_auth, flutter_secure_storage)
// needs a FragmentActivity.
class MainActivity : FlutterFragmentActivity() {
    private var updater: AppUpdater? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        // Lets Dart set FLAG_SECURE while the recovery phrase is on screen.
        MethodChannel(messenger, "epic_wallet/secure_screen")
            .setMethodCallHandler { call, result ->
                if (call.method == "setSecure") {
                    if (call.arguments == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        val channel = MethodChannel(messenger, "epic_wallet/updater")
        updater = AppUpdater(this, channel).also { channel.setMethodCallHandler(it) }
    }

    override fun onDestroy() {
        updater?.detach()
        updater = null
        super.onDestroy()
    }
}
