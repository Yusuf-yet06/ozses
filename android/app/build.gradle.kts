plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // 🛡️ Siber Kimlik: Paket adınla eşleştiğinden emin ol
    namespace = "com.example.ozses_v7_imperium"
    compileSdk = 36 // 🎯 SİBER ŞAPLAK 1: Android SDK 36 Zırhı
    ndkVersion = "28.2.13676358" // 🎯 SİBER ŞAPLAK 2: Yeni Nesil NDK Motoru

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        // Bu ID, Google Play ve telefonun için benzersiz mühürdür
        applicationId = "com.example.ozses_v7_imperium"
        
        // 🚀 Siber Güvenlik Sınırı: Telefonunun istediği minimum seviye
        minSdk = 24 
        targetSdk = 35
        
        versionCode = 1
        versionName = "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    // ⚡ Java ve Kotlin Senkronizasyonu
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    buildTypes {
        getByName("release") {
            // İleride imzalama (signing) ayarlarını buraya ekleyeceğiz gardaşım
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
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