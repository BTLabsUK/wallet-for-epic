package com.blacktyger.epic_wallet

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity, because the biometric prompt (local_auth, flutter_secure_storage)
// needs a FragmentActivity.
private const val MAX_BYTES = 1 shl 20

class MainActivity : FlutterFragmentActivity() {
    private var updater: AppUpdater? = null
    private var incomingChannel: MethodChannel? = null

    /** A transaction file another app handed us before Dart asked for it. */
    private var pendingFile: Map<String, String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()
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
        // Transaction files opened or shared from other apps (Telegram, mail, files).
        incomingChannel = MethodChannel(messenger, "epic_wallet/incoming_slate").also {
            it.setMethodCallHandler { call, result ->
                if (call.method == "takePending") {
                    result.success(pendingFile)
                    pendingFile = null
                } else {
                    result.notImplemented()
                }
            }
        }
        readIncoming(intent)?.let { pendingFile = it }
        val channel = MethodChannel(messenger, "epic_wallet/updater")
        updater = AppUpdater(this, channel).also { channel.setMethodCallHandler(it) }
    }

    /** The channel background pushes land in, named in AndroidManifest.xml. */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < 26) return
        val channel = NotificationChannel(
            "transactions",
            "Transactions",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply { description = "Incoming payments and sends waiting to be finished" }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val file = readIncoming(intent) ?: return
        val channel = incomingChannel
        if (channel == null) {
            pendingFile = file
        } else {
            // Dart listens only once a wallet screen has asked; until then keep the file.
            channel.invokeMethod("incoming", file, object : MethodChannel.Result {
                override fun success(result: Any?) {}
                override fun error(code: String, message: String?, details: Any?) {
                    pendingFile = file
                }
                override fun notImplemented() {
                    pendingFile = file
                }
            })
        }
    }

    /** Name and text of a transaction file from a VIEW or SEND intent, or null. */
    private fun readIncoming(intent: Intent?): Map<String, String>? {
        val uri: Uri = when (intent?.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> if (Build.VERSION.SDK_INT >= 33) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION") intent.getParcelableExtra(Intent.EXTRA_STREAM)
            }
            else -> null
        } ?: return null
        return try {
            var name = uri.lastPathSegment ?: "transaction.tx"
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
                if (it.moveToFirst()) it.getString(0)?.let { n -> name = n }
            }
            val bytes = contentResolver.openInputStream(uri)?.use { input ->
                // Slate files are a few kilobytes; read at most 1 MB plus one byte to detect more.
                val buffer = input.readNBytesCompat(MAX_BYTES + 1)
                if (buffer.size > MAX_BYTES) return null
                buffer
            } ?: return null
            mapOf("name" to name.substringAfterLast('/'), "text" to String(bytes, Charsets.UTF_8))
        } catch (e: Exception) {
            null
        }
    }

    private fun java.io.InputStream.readNBytesCompat(limit: Int): ByteArray {
        val out = java.io.ByteArrayOutputStream()
        val chunk = ByteArray(8192)
        while (out.size() < limit) {
            val n = read(chunk, 0, minOf(chunk.size, limit - out.size()))
            if (n < 0) break
            out.write(chunk, 0, n)
        }
        return out.toByteArray()
    }

    override fun onDestroy() {
        updater?.detach()
        updater = null
        super.onDestroy()
    }
}
