package com.blacktyger.epic_wallet

import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageInstaller
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Installs a downloaded update through [PackageInstaller].
 *
 * Dart downloads the APK and checks its SHA-256. This side checks that the file is this app, is
 * newer, and carries the same signing certificate, so a bad download fails with a clear reason
 * instead of a system error. The system still shows its install confirmation, except on
 * Android 12+ once this app is the installer of record, where it may update without asking.
 */
class AppUpdater(
    private val activity: Activity,
    private val channel: MethodChannel,
) : MethodChannel.MethodCallHandler {

    init {
        listener = { status, message ->
            activity.runOnUiThread {
                channel.invokeMethod("installStatus", mapOf("status" to status, "message" to message))
            }
        }
    }

    fun detach() {
        listener = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "appInfo" -> result.success(appInfo())
            "requestInstallPermission" -> {
                openInstallSettings()
                result.success(null)
            }
            "install" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("bad_args", "path is required", null)
                } else {
                    // File checks and the session copy are quick for a ~35 MB APK, but keep
                    // them off the UI thread anyway.
                    Thread {
                        val outcome = try {
                            install(File(path))
                        } catch (e: Exception) {
                            mapOf("status" to "failed", "message" to (e.message ?: e.toString()))
                        }
                        activity.runOnUiThread { result.success(outcome) }
                    }.start()
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun installedInfo(flags: Int = 0): PackageInfo =
        activity.packageManager.getPackageInfo(activity.packageName, flags)

    private fun versionCodeOf(info: PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else @Suppress("DEPRECATION") info.versionCode.toLong()

    private fun appInfo(): Map<String, Any?> {
        val info = installedInfo()
        val canInstall = Build.VERSION.SDK_INT < 26 || activity.packageManager.canRequestPackageInstalls()
        return mapOf(
            "packageName" to activity.packageName,
            "versionCode" to versionCodeOf(info),
            "versionName" to info.versionName,
            "abis" to Build.SUPPORTED_ABIS.toList(),
            "sdk" to Build.VERSION.SDK_INT,
            "canInstall" to canInstall,
        )
    }

    private fun signers(info: PackageInfo?): Set<String>? {
        if (Build.VERSION.SDK_INT < 28) return null
        val signing = info?.signingInfo ?: return null
        val certs = if (signing.hasMultipleSigners()) signing.apkContentsSigners else signing.signingCertificateHistory
        return certs?.map { it.toCharsString() }?.toSet()
    }

    private fun install(apk: File): Map<String, Any?> {
        if (!apk.isFile) return failed("the downloaded file is missing")
        val pm = activity.packageManager
        val flags = if (Build.VERSION.SDK_INT >= 28) PackageManager.GET_SIGNING_CERTIFICATES else 0
        val archive = pm.getPackageArchiveInfo(apk.path, flags)
            ?: return failed("the download is not a valid APK")
        if (archive.packageName != activity.packageName) {
            return failed("the APK is for ${archive.packageName}, not this app")
        }
        val installed = installedInfo(flags)
        if (versionCodeOf(archive) <= versionCodeOf(installed)) {
            return failed("the APK is not newer than the installed version")
        }
        val theirs = signers(archive)
        val ours = signers(installed)
        if (theirs != null && ours != null && theirs.intersect(ours).isEmpty()) {
            // Android never installs it over this app: Dart asks for a reinstall instead.
            return mapOf("status" to "keyMismatch", "message" to null)
        }
        if (Build.VERSION.SDK_INT >= 26 && !pm.canRequestPackageInstalls()) {
            openInstallSettings()
            return mapOf("status" to "needsPermission", "message" to null)
        }

        val installer = pm.packageInstaller
        val params = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL)
        params.setAppPackageName(activity.packageName)
        params.setSize(apk.length())
        if (Build.VERSION.SDK_INT >= 31) {
            params.setRequireUserAction(PackageInstaller.SessionParams.USER_ACTION_NOT_REQUIRED)
        }
        val sessionId = installer.createSession(params)
        try {
            installer.openSession(sessionId).use { session ->
                apk.inputStream().use { input ->
                    session.openWrite("base.apk", 0, apk.length()).use { output ->
                        input.copyTo(output)
                        session.fsync(output)
                    }
                }
                val intent = Intent(activity, InstallResultReceiver::class.java)
                val piFlags = PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0)
                val pending = PendingIntent.getBroadcast(activity, sessionId, intent, piFlags)
                session.commit(pending.intentSender)
            }
        } catch (e: Exception) {
            installer.abandonSession(sessionId)
            throw e
        }
        return mapOf("status" to "started", "message" to null)
    }

    private fun failed(message: String) = mapOf("status" to "failed", "message" to message)

    /**
     * Opens Android's "allow from this source" screen for this app (Android 8+; nothing to ask
     * before). Dart asks before it downloads, so the download is never lost to the trip there.
     */
    private fun openInstallSettings() {
        if (Build.VERSION.SDK_INT < 26) return
        val settings = Intent(
            Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
            Uri.parse("package:${activity.packageName}"),
        )
        activity.runOnUiThread { activity.startActivity(settings) }
    }

    companion object {
        /** Forwards install results to Dart while the activity lives. */
        @Volatile
        var listener: ((String, String?) -> Unit)? = null
    }
}

/** Receives [PackageInstaller] results. On success the process is replaced by the new version. */
class InstallResultReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)
        val message = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)
        when (status) {
            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                val confirm = if (Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
                } else {
                    @Suppress("DEPRECATION") intent.getParcelableExtra(Intent.EXTRA_INTENT)
                }
                if (confirm != null) {
                    confirm.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(confirm)
                }
                AppUpdater.listener?.invoke("pendingUserAction", null)
            }
            PackageInstaller.STATUS_SUCCESS -> AppUpdater.listener?.invoke("success", null)
            PackageInstaller.STATUS_FAILURE_ABORTED -> AppUpdater.listener?.invoke("cancelled", message)
            else -> AppUpdater.listener?.invoke("failed", message ?: "install failed ($status)")
        }
    }
}
