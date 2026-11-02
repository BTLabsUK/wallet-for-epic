// SPDX-License-Identifier: Apache-2.0
package uk.btlabs.btwallet

import android.app.Activity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The store builds (WFE_DIST=play or fdroid, https://docs.btlabs.uk/developers/build/variants/) have no in-app updater: no
 * installer, no REQUEST_INSTALL_PACKAGES, no install result receiver. The store updates the app.
 * Dart never asks this channel in those builds; every call answers not implemented.
 * The real one is src/updater/kotlin/.../AppUpdater.kt, built only into WFE_DIST=web.
 */
@Suppress("UNUSED_PARAMETER")
class AppUpdater(activity: Activity, channel: MethodChannel) : MethodChannel.MethodCallHandler {
    fun detach() {}

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) = result.notImplemented()
}
