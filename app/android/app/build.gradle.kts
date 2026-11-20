import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing (upload key for Google Play). android/key.properties is not in git.
// Keys: storeFile, storePassword, keyAlias, keyPassword. A relative storeFile is
// relative to this folder (android/app). On Windows, write the path with forward
// slashes (D:/keys/upload.jks): a backslash is an escape character in this file.
// Without the file, release builds use the debug key, and Google Play rejects them.
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties: Properties? =
    if (keyPropertiesFile.isFile) {
        Properties().apply { keyPropertiesFile.inputStream().use { load(it) } }
    } else {
        null
    }

fun keyProperty(name: String): String =
    keyProperties?.getProperty(name)?.takeIf { it.isNotBlank() }
        ?: throw GradleException("${keyPropertiesFile.path}: '$name' is missing or empty.")

android {
    namespace = "com.arkhipenko.epub_reader"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Same id as the iOS PRODUCT_BUNDLE_IDENTIFIER. Do not change it after the first
        // Google Play upload: a new id is a different app.
        applicationId = "com.smart4smart.koreader"
        // Android 8.0. Agreed minimum for the app.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keyProperties != null) {
            create("release") {
                val store = file(keyProperty("storeFile"))
                if (!store.isFile) {
                    throw GradleException("${keyPropertiesFile.path}: keystore not found: ${store.path}")
                }
                storeFile = store
                storePassword = keyProperty("storePassword")
                keyAlias = keyProperty("keyAlias")
                keyPassword = keyProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (keyProperties != null) {
                    signingConfigs.getByName("release")
                } else {
                    if (gradle.startParameter.taskNames.any { it.contains("Release") }) {
                        logger.warn(
                            "WARNING: ${keyPropertiesFile.path} not found. This release build " +
                                "uses the debug key. Google Play does not accept it.",
                        )
                    }
                    signingConfigs.getByName("debug")
                }
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
