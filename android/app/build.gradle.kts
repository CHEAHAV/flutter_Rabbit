plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.rabbit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.rabbit"
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

// Publish each built APK under the app's own name, so what gets handed round is
// Rabbit.apk rather than app-release.apk.
//
// This is a copy, not a rename, on purpose: the Flutter Gradle plugin hard-codes
// the name `app-<abi>?-<flavor>?-<mode>.apk` when it copies the APK into
// build/app/outputs/flutter-apk, and `flutter build apk` exits with "Gradle
// build failed to produce an .apk file" if that exact name is not there
// afterwards. So the plugin's file is left alone and ours is written beside it.
//
// Only the release build takes the bare name; debug and profile keep a suffix so
// they cannot quietly overwrite the APK meant for distribution. A split-per-abi
// build keeps its abi in the middle (Rabbit-arm64-v8a.apk).
val appApkName = "Rabbit"

project.afterEvaluate {
    android.applicationVariants.forEach { variant ->
        val mode = variant.buildType.name
        val assembleTaskName = "assemble" + variant.name.replaceFirstChar { it.uppercase() }
        tasks.findByName(assembleTaskName)?.doLast {
            val apkDir = layout.buildDirectory.dir("outputs/flutter-apk").get().asFile
            val built = apkDir.listFiles { file ->
                file.name.startsWith("app") && file.name.endsWith("-$mode.apk")
            } ?: return@doLast
            built.forEach { apk ->
                val middle = apk.name.removePrefix("app").removeSuffix("-$mode.apk")
                val suffix = if (mode == "release") "" else "-$mode"
                val target = apkDir.resolve("$appApkName$middle$suffix.apk")
                apk.copyTo(target, overwrite = true)
                logger.lifecycle("Built ${target.path}")
            }
        }
    }
}
