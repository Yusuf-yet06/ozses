import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // 🛡️ Siber Kimlik: Firebase ve Google Play için benzersiz mühür
    namespace = "com.ozses.imperium"
    compileSdk = 36 // 🎯 Android SDK 36 Zırhı
    ndkVersion = "28.2.13676358" // 🎯 Yeni Nesil NDK Motoru

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        // Bu ID, Google Play ve telefonun için benzersiz mühürdür
        applicationId = "com.ozses.imperium"
        
        // 🚀 Siber Güvenlik Sınırı: Google Play 2026 zorunlu hedef seviyesi
        minSdk = 24 
        targetSdk = 36
        
        versionCode = 19
        versionName = "1.0.16"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                val storeFilePath = keystoreProperties["storeFile"] as String
                val resolvedFile = file(storeFilePath)
                storeFile = if (resolvedFile.exists()) resolvedFile else rootProject.file(storeFilePath)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    // ⚡ Java ve Kotlin Senkronizasyonu
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = if (keystorePropertiesFile.exists() && signingConfigs.getByName("release").storeFile?.exists() == true) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Standart Kotlin kütüphanesi
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.22")
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8)
    }
}
