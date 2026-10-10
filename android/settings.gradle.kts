pluginManagement {
    val flutterSdkPath =
        run {
            // Try local.properties first (local builds), then FLUTTER_ROOT env (CI builds)
            val fromProps = try {
                val properties = java.util.Properties()
                file("local.properties").inputStream().use { properties.load(it) }
                properties.getProperty("flutter.sdk")
            } catch (e: Exception) { null }
            val flutterSdkPath = fromProps ?: System.getenv("FLUTTER_ROOT")
            require(!flutterSdkPath.isNullOrEmpty()) { "flutter.sdk not set in local.properties and FLUTTER_ROOT env not set" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // NOTE (VM build): skip .module metadata for Google's repo because
        // dl.google.com serves very slow 404s for .module files here.
        google {
            metadataSources {
                mavenPom()
                artifact()
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.6.1" apply false
    id("org.jetbrains.kotlin.android") version "2.0.20" apply false
}

include(":app")
