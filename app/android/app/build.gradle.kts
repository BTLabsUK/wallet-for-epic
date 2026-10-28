import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. Release builds are signed with the release key only, never the debug key.
// The keystore and its passwords live outside every repository, in a key.properties file
// (storeFile, storePassword, keyAlias, keyPassword) found at WFE_ANDROID_KEY_PROPERTIES, else
// -PwfeKeyProperties=<path>, else ~/.config/btlabs/android/key.properties. Without a usable one,
// checkReleaseSigning stops every release build; debug builds never read it.
val releaseKeyProperties: File = file(
    System.getenv("WFE_ANDROID_KEY_PROPERTIES")
        ?: (findProperty("wfeKeyProperties") as String?)
        ?: "${System.getProperty("user.home")}/.config/btlabs/android/key.properties",
)
val releaseKey: Properties? = releaseKeyProperties.takeIf { it.isFile }
    ?.let { f -> Properties().apply { f.inputStream().use { load(it) } } }

// Why the release key cannot be used, or null when it can.
val releaseSigningProblem: String? = run {
    val props = releaseKey ?: return@run "$releaseKeyProperties is missing"
    val missing = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        .filter { props.getProperty(it).isNullOrBlank() }
    if (missing.isNotEmpty()) return@run "$releaseKeyProperties lacks ${missing.joinToString()}"
    val store = file(props.getProperty("storeFile"))
    // app/android is the Gradle root; the repository is two levels up.
    val repo = rootProject.projectDir.canonicalFile.parentFile.parentFile
    when {
        !store.isFile -> "the keystore named in $releaseKeyProperties is missing"
        store.canonicalPath.startsWith(repo.path + File.separator) ->
            "the keystore is inside the repository; keep it outside"
        store.name == "debug.keystore" || props.getProperty("keyAlias") == "androiddebugkey" ->
            "$releaseKeyProperties names the debug key"
        else -> null
    }
}

// Flutter hands its --dart-define values to Gradle as `dart-defines` (base64, comma separated).
val dartDefines: List<String> = (project.findProperty("dart-defines") as String?).orEmpty()
    .split(",")
    .filter { it.isNotEmpty() }
    .map { String(Base64.getDecoder().decode(it)) }

// The build without Tor (lib/src/tor_build.dart, https://docs.btlabs.uk/developers/build/variants/). With WFE_TOR=false
// (or 0, off) no tor is packed, even when tools/fetch-tor.sh left one in src/main/tor-jniLibs.
val torBuilt = dartDefines.none { it in setOf("WFE_TOR=false", "WFE_TOR=0", "WFE_TOR=off") }

// Where the build is distributed (lib/src/dist_build.dart, https://docs.btlabs.uk/developers/build/variants/): web (unset, our
// own download page), play (Google Play) or fdroid (F-Droid, IzzyOnDroid). Only web has the
// in-app updater and its install permissions (src/updater/). msstore is the Windows build only.
val dist: String = dartDefines.lastOrNull { it.startsWith("WFE_DIST=") }?.removePrefix("WFE_DIST=") ?: "web"
if (dist !in setOf("web", "play", "fdroid")) {
    throw GradleException("WFE_DIST=$dist: use web, play or fdroid on Android (https://docs.btlabs.uk/developers/build/variants/).")
}
val distUpdates = dist == "web"
// The F-Droid build reads QR codes with a free scanner: Google ML Kit (mobile_scanner) must be
// gone from pubspec.yaml before Gradle runs.
if (dist == "fdroid" && rootProject.findProject(":mobile_scanner") != null) { // dist-prep: names only
    throw GradleException(
        "WFE_DIST=fdroid with the Google ML Kit scanner still in pubspec.yaml: run " +
            "tools/dist-prep.sh fdroid first (https://docs.btlabs.uk/developers/build/variants/).",
    )
}

android {
    namespace = "uk.btlabs.epiccash.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Epic Cash Mobile; the namespace and the Kotlin package are the same. Its own app beside
        // the builds before it, which carried the developer's old ids: installing it never
        // replaces them, and its data starts empty (app/README.md, "App ids and data folders").
        applicationId = "uk.btlabs.epiccash.mobile"
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
        // The Play bundle is arm64 only, like the APK. Flutter compiles the app for the
        // --target-platform alone, but plugins (ML Kit, CameraX) and tor bring their own other
        // ABIs: Play would serve those phones a split without libflutter.so.
        if (dist == "play") ndk { abiFilters += "arm64-v8a" }
    }

    // tools/fetch-tor.sh android puts the Tor Project's tor here as <abi>/libtor.so. It is an
    // executable, and Android only runs files from the app's native library folder, so the
    // libraries are extracted at install (extractNativeLibs) instead of being mapped from the APK.
    // Without Tor neither: the libraries stay in the APK, uncompressed and page aligned.
    if (torBuilt) sourceSets["main"].jniLibs.srcDir("src/main/tor-jniLibs")
    packaging {
        jniLibs {
            useLegacyPackaging = torBuilt
        }
    }

    signingConfigs {
        create("release") {
            if (releaseSigningProblem == null) {
                val props = releaseKey!!
                storeFile = file(props.getProperty("storeFile"))
                storePassword = props.getProperty("storePassword")
                keyAlias = props.getProperty("keyAlias")
                keyPassword = props.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// The in-app updater follows WFE_DIST: its Kotlin (or a stub that answers nothing), in the main
// source set where the Kotlin plugin compiles it, and its manifest, merged into every variant.
android.sourceSets["main"].java.srcDir(if (distUpdates) "src/updater/kotlin" else "src/noupdater/kotlin")
androidComponents {
    onVariants { variant ->
        if (distUpdates) variant.sources.manifests.addStaticManifestFile("src/updater/AndroidManifest.xml")
    }
}

val checkReleaseSigning by tasks.registering {
    val problem = releaseSigningProblem
    doLast {
        if (problem != null) {
            throw GradleException(
                "Release builds are signed with the release key only, and it cannot be used: " +
                    "$problem. Set WFE_ANDROID_KEY_PROPERTIES to the release key.properties " +
                    "(app/README.md, \"Release signing\").",
            )
        }
    }
}
tasks.matching { it.name == "preReleaseBuild" }.configureEach { dependsOn(checkReleaseSigning) }

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
