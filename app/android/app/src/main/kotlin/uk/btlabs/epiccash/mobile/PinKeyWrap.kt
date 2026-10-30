// SPDX-License-Identifier: Apache-2.0
package uk.btlabs.epiccash.mobile

import android.app.KeyguardManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import java.security.UnrecoverableKeyException
import java.util.concurrent.Executors
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Non-exportable AES-GCM keys in the Android Keystore that wrap the PIN key and the PIN failure
 * count of the app's store (`pin_wrap.dart` decides what is wrapped and when keys rotate). A copy
 * of the store taken off the phone holds only text these keys sealed, so it cannot be searched
 * for the PIN; a rotated key is deleted, so an older copy put back cannot be opened either.
 *
 * Errors: `lost` when the key is gone or can no longer open the text (the wallet then needs its
 * recovery phrase), `unavailable` for anything that may pass (a locked phone, a busy Keystore).
 */
class PinKeyWrap private constructor(private val context: Context) : MethodChannel.MethodCallHandler {
    // Keystore and StrongBox calls can take a while; never on the UI thread.
    private val worker = Executors.newSingleThreadExecutor()
    private val main = android.os.Handler(android.os.Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        worker.execute {
            val answer: Any? = try {
                when (call.method) {
                    "create" -> create(call.argument<String>("alias")!!)
                    "seal" -> seal(
                        call.argument<String>("alias")!!,
                        call.argument<String>("name")!!,
                        call.argument<String>("text")!!,
                    )
                    "open" -> open(
                        call.argument<String>("alias")!!,
                        call.argument<String>("name")!!,
                        call.argument<String>("blob")!!,
                    )
                    "delete" -> {
                        keyStore().deleteEntry(call.argument<String>("alias")!!)
                        null
                    }
                    "aliases" -> {
                        val prefix = call.argument<String>("prefix")!!
                        keyStore().aliases().toList().filter { it.startsWith(prefix) }
                    }
                    else -> {
                        main.post { result.notImplemented() }
                        return@execute
                    }
                }
            } catch (e: Lost) {
                main.post { result.error("lost", e.message, null) }
                return@execute
            } catch (e: Exception) {
                // Only the exception's class: its message can name the alias, never a secret.
                main.post { result.error("unavailable", e.javaClass.simpleName, null) }
                return@execute
            }
            main.post { result.success(answer) }
        }
    }

    private class Lost(message: String) : Exception(message)

    private fun keyStore(): KeyStore = KeyStore.getInstance(KEYSTORE).apply { load(null) }

    /**
     * Makes the key [alias], the strongest kind this phone keeps working: StrongBox where it has
     * one, and unlocked-device-required where that cannot cost the key (see [unlockedRequiredSafe]).
     * Each kind is tried with a seal and an open before it is kept. Returns what the key got.
     */
    private fun create(alias: String): Map<String, Boolean> {
        val strongBox = Build.VERSION.SDK_INT >= 28 &&
            context.packageManager.hasSystemFeature(PackageManager.FEATURE_STRONGBOX_KEYSTORE)
        val unlocked = unlockedRequiredSafe()
        val kinds = listOf(
            strongBox to unlocked,
            strongBox to false,
            false to unlocked,
            false to false,
        ).distinct().filter { (sb, ul) -> (!sb || strongBox) && (!ul || unlocked) }
        var last: Exception? = null
        for ((sb, ul) in kinds) {
            try {
                generate(alias, sb, ul)
                val probe = seal(alias, "probe", "probe")
                if (open(alias, "probe", probe) == "probe") {
                    return mapOf("strongBox" to sb, "unlockedRequired" to ul)
                }
            } catch (e: Exception) {
                last = e
            }
            try {
                keyStore().deleteEntry(alias)
            } catch (_: Exception) {
            }
        }
        throw last ?: IllegalStateException("no key kind works")
    }

    /**
     * Unlocked-device-required only where it cannot make the key vanish: the phone has a secure
     * lock screen, and the Android version does not delete such keys when that lock screen is
     * removed. Android 12 to 14 tie them to the lock screen's credential (fixed in 15), so there
     * a user who turns the screen lock off would need the recovery phrase.
     */
    private fun unlockedRequiredSafe(): Boolean {
        val sdk = Build.VERSION.SDK_INT
        if (sdk < 28 || sdk in 31..34) return false
        val keyguard = context.getSystemService(KeyguardManager::class.java) ?: return false
        return keyguard.isDeviceSecure
    }

    private fun generate(alias: String, strongBox: Boolean, unlockedRequired: Boolean) {
        val spec = KeyGenParameterSpec.Builder(
            alias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .setRandomizedEncryptionRequired(true)
        if (Build.VERSION.SDK_INT >= 28) {
            spec.setIsStrongBoxBacked(strongBox)
            spec.setUnlockedDeviceRequired(unlockedRequired)
        }
        KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE).apply {
            init(spec.build())
            generateKey()
        }
    }

    private fun key(alias: String): SecretKey {
        val key = try {
            keyStore().getKey(alias, null)
        } catch (e: UnrecoverableKeyException) {
            throw Lost("key unrecoverable")
        }
        return key as? SecretKey ?: throw Lost("no key")
    }

    /** [text] sealed under [alias], bound to [name] so it cannot be moved to another entry. */
    private fun seal(alias: String, name: String, text: String): String {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        try {
            cipher.init(Cipher.ENCRYPT_MODE, key(alias))
        } catch (e: KeyPermanentlyInvalidatedException) {
            throw Lost("key invalidated")
        }
        cipher.updateAAD(name.toByteArray(Charsets.UTF_8))
        val sealed = cipher.doFinal(text.toByteArray(Charsets.UTF_8))
        return Base64.encodeToString(cipher.iv + sealed, Base64.NO_WRAP)
    }

    private fun open(alias: String, name: String, blob: String): String {
        val bytes = try {
            Base64.decode(blob, Base64.NO_WRAP)
        } catch (e: IllegalArgumentException) {
            throw Lost("damaged text")
        }
        if (bytes.size < IV_LEN + TAG_LEN) throw Lost("damaged text")
        val cipher = Cipher.getInstance(TRANSFORMATION)
        try {
            cipher.init(
                Cipher.DECRYPT_MODE,
                key(alias),
                GCMParameterSpec(TAG_LEN * 8, bytes, 0, IV_LEN),
            )
        } catch (e: KeyPermanentlyInvalidatedException) {
            throw Lost("key invalidated")
        }
        cipher.updateAAD(name.toByteArray(Charsets.UTF_8))
        val plain = try {
            cipher.doFinal(bytes, IV_LEN, bytes.size - IV_LEN)
        } catch (e: AEADBadTagException) {
            throw Lost("text does not open")
        }
        return String(plain, Charsets.UTF_8)
    }

    fun dispose() {
        worker.shutdown()
    }

    companion object {
        private const val KEYSTORE = "AndroidKeyStore"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val IV_LEN = 12
        private const val TAG_LEN = 16

        fun register(context: Context, messenger: BinaryMessenger): PinKeyWrap {
            val wrap = PinKeyWrap(context.applicationContext)
            MethodChannel(messenger, "epic_wallet/pin_wrap").setMethodCallHandler(wrap)
            return wrap
        }
    }
}
