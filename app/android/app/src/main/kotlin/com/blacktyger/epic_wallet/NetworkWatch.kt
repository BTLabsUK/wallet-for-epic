package com.blacktyger.epic_wallet

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

/**
 * Tells Dart when the default network comes back ("available") or goes ("lost"), so a tor
 * that died with the network is started again (phone_tor.dart). Registered only while Dart
 * listens, which is while the activity's engine lives; nothing runs in the background.
 */
class NetworkWatch(private val context: Context) : EventChannel.StreamHandler {
    private val main = Handler(Looper.getMainLooper())
    private var callback: ConnectivityManager.NetworkCallback? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val manager = context.getSystemService(ConnectivityManager::class.java) ?: return
        val cb = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                main.post { events.success("available") }
            }

            override fun onLost(network: Network) {
                main.post { events.success("lost") }
            }
        }
        try {
            manager.registerDefaultNetworkCallback(cb)
            callback = cb
        } catch (e: RuntimeException) {
            // Too many callbacks, or no permission: Dart still restarts on resume.
        }
    }

    override fun onCancel(arguments: Any?) {
        val cb = callback ?: return
        callback = null
        try {
            context.getSystemService(ConnectivityManager::class.java)?.unregisterNetworkCallback(cb)
        } catch (e: IllegalArgumentException) {
        }
    }

    companion object {
        fun register(context: Context, messenger: BinaryMessenger) {
            EventChannel(messenger, "epic_wallet/network").setStreamHandler(NetworkWatch(context))
        }
    }
}
