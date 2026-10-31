// SPDX-License-Identifier: Apache-2.0
package uk.btlabs.epiccash.mobile

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
private const val MAX_LINK_CHARS = 4096

/** ClipDescription.EXTRA_IS_SENSITIVE (API 33), by value so older SDK levels compile. */
private const val EXTRA_IS_SENSITIVE = "android.content.extra.IS_SENSITIVE"

class MainActivity : FlutterFragmentActivity() {
    private var updater: AppUpdater? = null
    private var incomingChannel: MethodChannel? = null
    private var networkWatch: NetworkWatch? = null
    private var pinKeyWrap: PinKeyWrap? = null

    /** A transaction file another app handed us before Dart asked for it. */
    private var pendingFile: Map<String, String>? = null

    private var linkChannel: MethodChannel? = null

    /** An epic: / epiccash: payment link another app opened, before Dart asked for it. */
    private var pendingLink: String? = null

    /** The activity was recreated from saved state: its intent was handled before. */
    private var restored = false

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        restored = savedInstanceState != null
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        removeOldNotificationChannel()
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        // Lets Dart block screenshots, screen recording and the recent-apps preview
        // (FLAG_SECURE) while a payment QR is on screen, hide only the recent-apps preview while
        // a recovery phrase is shown, copy a phrase as sensitive clipboard content, keep the
        // screen on (FLAG_KEEP_SCREEN_ON) during a restore's scan, and open the app's settings.
        MethodChannel(messenger, "epic_wallet/secure_screen")
            .setMethodCallHandler { call, result ->
                if (call.method == "setSecure") {
                    secureWanted = call.arguments == true
                    if (secureWanted) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                } else if (call.method == "hidePreview") {
                    // Android 13+: no recent-apps thumbnail, screenshots still allowed (the
                    // phrase screens). Older versions have no switch for the preview alone.
                    if (Build.VERSION.SDK_INT >= 33) {
                        setRecentsScreenshotEnabled(call.arguments != true)
                    }
                    result.success(Build.VERSION.SDK_INT >= 33)
                } else if (call.method == "copySensitive") {
                    // A recovery phrase or other secret text: marked sensitive, so Android 13+
                    // hides it from the copy preview and keyboards leave it out of their
                    // clipboard history. With clearAfterMs it is cleared once that has passed,
                    // even if the app was killed meanwhile (clearExpiredClip).
                    val text = call.argument<String>("text")
                    val clearAfter = call.argument<Number>("clearAfterMs")?.toLong()
                    if (text == null) {
                        result.success(false)
                    } else {
                        try {
                            val clipboard = getSystemService(CLIPBOARD_SERVICE) as android.content.ClipboardManager
                            val clip = android.content.ClipData.newPlainText("", text)
                            clip.description.extras = android.os.PersistableBundle().apply {
                                putBoolean(EXTRA_IS_SENSITIVE, true)
                            }
                            clipboard.setPrimaryClip(clip)
                            if (clearAfter != null) stampClip(clipboard, clearAfter)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                } else if (call.method == "clearSensitive") {
                    // The secret copied last, now: still ours, it goes.
                    clearExpiredClip(force = true)
                    result.success(null)
                } else if (call.method == "keepScreenOn") {
                    // A restore's chain scan: the screen stays on, so Android does not cut the
                    // app's network while it runs.
                    if (call.arguments == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                    result.success(null)
                } else if (call.method == "openAppSettings") {
                    // The camera was refused: the page where the user can allow it again.
                    val settings = Intent(
                        android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.fromParts("package", packageName, null),
                    )
                    try {
                        startActivity(settings)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
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
        // Payment links (epic:, epiccash:), kept apart from files: the text is the link itself.
        linkChannel = MethodChannel(messenger, "epic_wallet/incoming_link").also {
            it.setMethodCallHandler { call, result ->
                if (call.method == "takePending") {
                    result.success(pendingLink)
                    pendingLink = null
                } else {
                    result.notImplemented()
                }
            }
        }
        // Once only: a launch from Recents or a restored activity carries the old intent again,
        // and a link the user already followed (and maybe paid) must not open a second time.
        if (!restored && intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY == 0) {
            readLink(intent)?.let {
                pendingLink = it
                intent = Intent(intent).setData(null)
            }
        }
        // --- tor binary (epic_wallet/tor) ---
        // The Tor Project's tor ships as lib/<abi>/libtor.so and is extracted at install
        // (useLegacyPackaging): the one place Android lets an app execute a file from.
        MethodChannel(messenger, "epic_wallet/tor")
            .setMethodCallHandler { call, result ->
                if (call.method == "binary") {
                    val file = java.io.File(applicationInfo.nativeLibraryDir, "libtor.so")
                    result.success(if (file.isFile) file.path else null)
                } else {
                    result.notImplemented()
                }
            }
        // --- end tor binary ---
        // How the last process ended, for the "stopped responding last time" offer.
        ExitReasons.register(applicationContext, messenger)
        val channel = MethodChannel(messenger, "epic_wallet/updater")
        updater = AppUpdater(this, channel).also { channel.setMethodCallHandler(it) }
        networkWatch?.dispose()
        networkWatch = NetworkWatch.register(applicationContext, messenger)
        // The PIN key and failure count under a Keystore key (PinKeyWrap.kt, pin_wrap.dart).
        pinKeyWrap?.dispose()
        pinKeyWrap = PinKeyWrap.register(applicationContext, messenger)
    }

    /** The payment QR asked for FLAG_SECURE; the privacy cover must not take it away. */
    private var secureWanted = false

    // --- privacy cover (Android 7–12) ---
    // Android 13+ hides the Recents preview of the phrase screens without blocking screenshots
    // (hidePreview, setRecentsScreenshotEnabled). Older versions have no such switch, so the
    // whole app sets FLAG_SECURE while it is away and clears it on return: the app switcher
    // shows a blank card, and screenshots in the foreground keep working.
    private fun coverForRecents(cover: Boolean) {
        if (Build.VERSION.SDK_INT >= 33 || secureWanted) return
        if (cover) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    override fun onUserLeaveHint() {
        // Home or Recents pressed: before onPause, so the snapshot already has the cover.
        coverForRecents(true)
        super.onUserLeaveHint()
    }

    override fun onPause() {
        coverForRecents(true)
        clearExpiredClip(force = false)
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        coverForRecents(false)
        clearExpiredClip(force = false)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        // Android 10+ lets only the focused app see the clipboard: the first moment after a
        // restart when an expired secret can be checked and cleared.
        if (hasFocus) clearExpiredClip(force = false)
    }
    // --- end privacy cover ---

    // --- secret clipboard expiry ---
    // When a secret was copied, kept in the app's preferences so a killed app still clears it at
    // its next start. Only times are kept, never the text.
    private fun clipPrefs() = getSharedPreferences("wfe_secret_clip", MODE_PRIVATE)

    private fun stampClip(clipboard: android.content.ClipboardManager, clearAfter: Long) {
        val stamp = if (Build.VERSION.SDK_INT >= 26) {
            try {
                clipboard.primaryClipDescription?.timestamp ?: -1L
            } catch (e: Exception) {
                -1L
            }
        } else {
            -1L
        }
        clipPrefs().edit()
            .putLong("copiedAt", System.currentTimeMillis())
            .putLong("clearAfter", clearAfter)
            .putLong("clipStamp", stamp)
            .apply()
    }

    /**
     * Clears the clipboard when the secret copied last is still on it and its time is up (or
     * [force]). A clip with another timestamp is someone else's and stays. An empty clipboard,
     * or Android before 8 with no timestamp, is cleared, as the secret may still be there.
     */
    private fun clearExpiredClip(force: Boolean) {
        val prefs = clipPrefs()
        val copiedAt = prefs.getLong("copiedAt", -1L)
        if (copiedAt < 0) return
        val age = System.currentTimeMillis() - copiedAt
        // A clock moved backwards also counts as expired.
        if (!force && age in 0 until prefs.getLong("clearAfter", 0L)) return
        // Android 10+ shows the clipboard only to the focused app: without focus, whose clip it
        // is cannot be told, so this waits for the focus to come back.
        if (Build.VERSION.SDK_INT >= 29 && !hasWindowFocus()) return
        try {
            val clipboard = getSystemService(CLIPBOARD_SERVICE) as android.content.ClipboardManager
            val stamp = prefs.getLong("clipStamp", -1L)
            val description = clipboard.primaryClipDescription
            val other = Build.VERSION.SDK_INT >= 26 && stamp >= 0 && description != null &&
                description.timestamp != stamp
            if (!other) {
                if (Build.VERSION.SDK_INT >= 28) {
                    clipboard.clearPrimaryClip()
                } else {
                    clipboard.setPrimaryClip(android.content.ClipData.newPlainText("", ""))
                }
            }
            prefs.edit().clear().apply()
        } catch (e: Exception) {
            // Kept for the next try.
        }
    }
    // --- end secret clipboard expiry ---

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        networkWatch?.dispose()
        networkWatch = null
        pinKeyWrap?.dispose()
        pinKeyWrap = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    /**
     * Versions up to 26.10.19 made a "Transactions" notification channel for push notifications,
     * which are gone; removing it takes the leftover entry out of the system's app settings.
     */
    private fun removeOldNotificationChannel() {
        if (Build.VERSION.SDK_INT < 26) return
        getSystemService(NotificationManager::class.java)?.deleteNotificationChannel("transactions")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        readLink(intent)?.let { link ->
            val channel = linkChannel
            if (channel == null) {
                pendingLink = link
            } else {
                channel.invokeMethod("link", link, object : MethodChannel.Result {
                    override fun success(result: Any?) {}
                    override fun error(code: String, message: String?, details: Any?) {
                        pendingLink = link
                    }
                    override fun notImplemented() {
                        pendingLink = link
                    }
                })
            }
            return
        }
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

    /**
     * The payment link of a VIEW intent whose scheme is epic or epiccash, or null. Only the data
     * string is read, never the extras, and never opened as a file.
     */
    private fun readLink(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_VIEW) return null
        val scheme = intent.data?.scheme?.lowercase() ?: return null
        if (scheme != "epic" && scheme != "epiccash") return null
        val text = intent.dataString ?: return null
        return if (text.length > MAX_LINK_CHARS) null else text
    }

    private fun isLinkScheme(intent: Intent?): Boolean {
        val scheme = intent?.data?.scheme?.lowercase()
        return intent?.action == Intent.ACTION_VIEW && (scheme == "epic" || scheme == "epiccash")
    }

    /** Name and text of a transaction file from a VIEW or SEND intent, or null. */
    private fun readIncoming(intent: Intent?): Map<String, String>? {
        if (readLink(intent) != null || isLinkScheme(intent)) return null
        val uri: Uri = when (intent?.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> if (Build.VERSION.SDK_INT >= 33) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION") intent.getParcelableExtra(Intent.EXTRA_STREAM)
            }
            else -> null
        } ?: return null
        if (!isForeignContent(uri)) return null
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

    /**
     * Whether [uri] is another app's content: the activity is exported, so any app can name it
     * with a file:// URI into this app's own folder, or a URI of one of this app's own
     * providers, and the read would run with this app's permissions.
     */
    private fun isForeignContent(uri: Uri): Boolean {
        if (uri.scheme?.lowercase() != "content") return false
        val authority = uri.authority ?: return false
        val owner = try {
            packageManager.resolveContentProvider(authority, 0)?.packageName
        } catch (e: Exception) {
            null
        }
        return owner != packageName
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
        networkWatch?.dispose()
        networkWatch = null
        super.onDestroy()
    }
}
