plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.luma.tv"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.luma.tv"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Sideloading builds use the debug signing config. Replace this with
            // your own keystore before publishing.
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

// 注：AGP 9.1 的 Kotlin DSL 不支持直接自定义 APK 输出文件名。
// Flutter CLI 又固定查找 app-<mode>.apk，所以这里在 assemble 之后
// 额外复制一份带版本号的文件，例如：
//   app-release.apk  ->  Luma_1.0.2_3_release.apk
val apkOutputDir = layout.buildDirectory.dir("outputs/flutter-apk")

fun registerCopyVersionedApk(mode: String) =
    tasks.register("copyVersionedApk${mode.replaceFirstChar { it.uppercase() }}") {
        group = "build"
        description = "复制 $mode APK 并附加 versionName/versionCode"
        doLast {
            val dir = apkOutputDir.get().asFile
            if (!dir.exists()) return@doLast
            val versionName = flutter.versionName
            val versionCode = flutter.versionCode
            dir.listFiles()
                ?.filter {
                    it.isFile &&
                        it.extension == "apk" &&
                        it.nameWithoutExtension.startsWith("app") &&
                        it.nameWithoutExtension.endsWith("-$mode")
                }
                ?.forEach { apk ->
                    // app-release.apk / app-arm64-v8a-release.apk
                    val rest = apk.nameWithoutExtension
                        .removePrefix("app")
                        .removePrefix("-")
                    val abi = rest.removeSuffix("-").removeSuffix(mode).trim('-')
                    val target = File(
                        dir,
                        listOf(
                            "Luma",
                            versionName,
                            versionCode.toString(),
                            abi,
                            mode,
                        ).filter { it.isNotEmpty() }.joinToString("_") + ".apk",
                    )
                    apk.copyTo(target, overwrite = true)
                    println("Versioned APK: ${target.absolutePath}")
                }
        }
    }

val copyVersionedApkDebug = registerCopyVersionedApk("debug")
val copyVersionedApkRelease = registerCopyVersionedApk("release")
val copyVersionedApkProfile = registerCopyVersionedApk("profile")

tasks.matching { it.name == "assembleDebug" }.configureEach {
    finalizedBy(copyVersionedApkDebug)
}
tasks.matching { it.name == "assembleRelease" }.configureEach {
    finalizedBy(copyVersionedApkRelease)
}
tasks.matching { it.name == "assembleProfile" }.configureEach {
    finalizedBy(copyVersionedApkProfile)
}
