package uk.btlabs.epiccash.mobile

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

/**
 * Tells Dart when the default network comes back ("available:wifi", "available:cellular", …)
 * or goes ("lost"), so a tor that died with the network is started again and the Epicbox
 * listener reconnects (phone_tor.dart, providers.dart). Registered only while Dart
 * listens, which is while the activity's engine lives; nothing runs in the background.
 * [dispose] when the engine goes away, in case Dart never cancelled.
 */
class NetworkWatch(private val context: Context) : EventChannel.StreamHandler {
    private val main = Handler(Looper.getMainLooper())
    private var callback: ConnectivityManager.NetworkCallback? = null
    private var channel: EventChannel? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val manager = context.getSystemService(ConnectivityManager::class.java) ?: return
        val cb = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) =
                post("available:" + kind(manager.getNetworkCapabilities(network)))

            override fun onLost(network: Network) = post("lost")

            // Not after Dart stopped listening.
            private fun post(event: String) {
                main.post { if (callback === this) events.success(event) }
            }
        }
        try {
            manager.registerDefaultNetworkCallback(cb)
            callback = cb
        } catch (e: RuntimeException) {
            // Too many callbacks, or no permission: Dart still restarts on resume.
        }
    }

    /** The network's transport, for the log. */
    private fun kind(caps: NetworkCapabilities?): String = when {
        caps == null -> "unknown"
        caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
        caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cellular"
        caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
        caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> "vpn"
        else -> "other"
    }

    override fun onCancel(arguments: Any?) {
        val cb = callback ?: return
        callback = null
        try {
            context.getSystemService(ConnectivityManager::class.java)?.unregisterNetworkCallback(cb)
        } catch (e: IllegalArgumentException) {
        }
    }

    /** Stops watching and leaves the channel; safe to call more than once. */
    fun dispose() {
        channel?.setStreamHandler(null)
        channel = null
        onCancel(null)
    }

    companion object {
        fun register(context: Context, messenger: BinaryMessenger): NetworkWatch {
            val watch = NetworkWatch(context)
            watch.channel = EventChannel(messenger, "epic_wallet/network").also {
                it.setStreamHandler(watch)
            }
            return watch
        }
    }
}
