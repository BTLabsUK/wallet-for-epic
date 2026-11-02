// SPDX-License-Identifier: Apache-2.0
package uk.btlabs.btwallet

import android.app.ActivityManager
import android.app.ApplicationExitInfo
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.InputStream

/** How much of a trace goes to Dart: the main thread of an ANR trace is at its start. */
private const val MAX_TRACE_BYTES = 256 * 1024

/**
 * How the app's last process ended, for the "stopped responding last time" offer
 * (last_session_io.dart). Android 11+ (API 30) keeps the reason (ANR, crash, native crash, a
 * kill) and, for an ANR, the threads' stacks at the freeze. Dart asks once at start with the
 * time of the newest end it has seen; the answer is the newest end after it, or none. Reads
 * nothing else and sends nothing anywhere.
 */
object ExitReasons {
    fun register(context: Context, messenger: BinaryMessenger) {
        val main = Handler(Looper.getMainLooper())
        MethodChannel(messenger, "epic_wallet/exit_reasons").setMethodCallHandler { call, result ->
            if (call.method != "lastExit") return@setMethodCallHandler result.notImplemented()
            if (Build.VERSION.SDK_INT < 30) return@setMethodCallHandler result.success(mapOf("supported" to false))
            val since = (call.argument<Number>("since") ?: 0).toLong()
            // A binder call and a file read: off the main thread.
            Thread {
                val answer = try {
                    mapOf("supported" to true, "exit" to newest(context, since))
                } catch (e: Exception) {
                    mapOf("supported" to true, "error" to e.javaClass.simpleName)
                }
                main.post { result.success(answer) }
            }.start()
        }
    }

    private fun newest(context: Context, since: Long): Map<String, Any?>? {
        if (Build.VERSION.SDK_INT < 30) return null
        val manager = context.getSystemService(ActivityManager::class.java) ?: return null
        // Newest first; the app's own process only (not a service process of a library).
        val info = manager.getHistoricalProcessExitReasons(context.packageName, 0, 5)
            .firstOrNull { it.processName == context.packageName } ?: return null
        if (info.timestamp <= since) return null
        val reason = when (info.reason) {
            ApplicationExitInfo.REASON_ANR -> "anr"
            ApplicationExitInfo.REASON_CRASH -> "crash"
            ApplicationExitInfo.REASON_CRASH_NATIVE -> "native"
            else -> "other"
        }
        val trace = when (info.reason) {
            ApplicationExitInfo.REASON_ANR -> info.traceInputStream?.use { readText(it) }
            // A tombstone (protobuf on Android 12+): its readable runs, as `strings` shows them,
            // hold the backtrace's library and function names.
            ApplicationExitInfo.REASON_CRASH_NATIVE -> info.traceInputStream?.use { readStrings(it) }
            else -> null
        }
        return mapOf(
            "reason" to reason,
            "timestamp" to info.timestamp,
            "description" to info.description,
            "trace" to trace,
        )
    }

    private fun readLimited(stream: InputStream): ByteArray {
        val out = java.io.ByteArrayOutputStream()
        val buf = ByteArray(16 * 1024)
        while (out.size() < MAX_TRACE_BYTES) {
            val n = stream.read(buf, 0, minOf(buf.size, MAX_TRACE_BYTES - out.size()))
            if (n < 0) break
            out.write(buf, 0, n)
        }
        return out.toByteArray()
    }

    private fun readText(stream: InputStream): String =
        String(readLimited(stream), Charsets.UTF_8)

    private fun readStrings(stream: InputStream): String {
        val bytes = readLimited(stream)
        val out = StringBuilder()
        val run = StringBuilder()
        fun flush() {
            if (run.length >= 4) out.append(run).append('\n')
            run.setLength(0)
        }
        for (b in bytes) {
            val c = b.toInt() and 0xff
            if (c in 0x20..0x7e) run.append(c.toChar()) else flush()
        }
        flush()
        return out.toString()
    }
}
