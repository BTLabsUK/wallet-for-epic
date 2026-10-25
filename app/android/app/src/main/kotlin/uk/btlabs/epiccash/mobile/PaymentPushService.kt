package uk.btlabs.epiccash.mobile

import android.app.ActivityManager
import android.app.KeyguardManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService

/**
 * Shows the push service's data-only message `{"type": "payment_waiting"}`, which FCM does not
 * display by itself. It carries no amount, sender or address, so neither does the notification.
 * Everything else, the token and the messages for Dart, is the firebase_messaging plugin's
 * service, which this extends (AndroidManifest.xml replaces the plugin's with it).
 */
class PaymentPushService : FlutterFirebaseMessagingService() {
    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        if (message.data["type"] != TYPE || appInForeground(this)) return
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_launcher_monochrome)
            .setContentTitle(getString(R.string.push_payment_waiting_title))
            .setContentText(getString(R.string.push_payment_waiting_text))
            .setContentIntent(open)
            .setAutoCancel(true)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()
        // One id: a new notification replaces the old one instead of stacking.
        getSystemService(NotificationManager::class.java).notify(NOTIFICATION_ID, notification)
    }

    private companion object {
        const val TYPE = "payment_waiting"

        /** The channel MainActivity creates and AndroidManifest.xml names as the default. */
        const val CHANNEL = "transactions"
        const val NOTIFICATION_ID = 1

        /** The wallet is on screen: Dart shows its own state, a notification would only nag. */
        fun appInForeground(context: Context): Boolean {
            val keyguard = context.getSystemService(KeyguardManager::class.java)
            if (keyguard?.isKeyguardLocked == true) return false
            val processes = context.getSystemService(ActivityManager::class.java)
                ?.runningAppProcesses ?: return false
            return processes.any {
                it.processName == context.packageName &&
                    it.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
            }
        }
    }
}
