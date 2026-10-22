plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.blacktyger.epic_wallet"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // 0.1.0 is its own app beside the 1.x test builds (com.blacktyger.epic_wallet, version
        // codes 2027+): installing it never replaces or downgrades them, and its data starts empty.
        applicationId = "com.blacktyger.epicwallet"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // tools/fetch-tor.sh android puts the Tor Project's tor here as <abi>/libtor.so. It is an
    // executable, and Android only runs files from the app's native library folder, so the
    // libraries are extracted at install (extractNativeLibs) instead of being mapped from the APK.
    sourceSets["main"].jniLibs.srcDir("src/main/tor-jniLibs")
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Firebase Cloud Messaging needs google-services.json, which stays out of git. A checkout
// without it still builds; pushes are then off, and lib/src/push.dart fails quietly.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
