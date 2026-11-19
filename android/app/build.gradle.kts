plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.agrocontrol"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {  
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.agrocontrol"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
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

// Sintaxis moderna en Kotlin DSL para forzar la versión del NDK en los submódulos (como :jni)
subprojects {
    project.pluginManager.withPlugin("com.android.library") {
        project.extensions.configure<com.android.build.api.dsl.LibraryExtension> {
            ndkVersion = "25.1.8937393"
        }
    }
    project.pluginManager.withPlugin("com.android.application") {
        project.extensions.configure<com.android.build.api.dsl.ApplicationExtension> {
            ndkVersion = "25.1.8937393"
        }
    }
}