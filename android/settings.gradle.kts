pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            // local.properties is UTF-8; Properties.load(InputStream) assumes
            // ISO-8859-1 and mangles non-ASCII Flutter SDK paths.
            file("local.properties").reader(charset = Charsets.UTF_8).use {
                properties.load(it)
            }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // Aliyun mirrors first: maven.google.com is unreachable on some networks.
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
