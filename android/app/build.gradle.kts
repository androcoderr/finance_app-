import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// İmza bilgileri android/key.properties dosyasından okunur (git'e girmez)
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

android {
    namespace = "com.finanscepte.app"
    compileSdk = 37  // bazı eklentiler (firebase, mlkit) en az bunu istiyor
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications (fatura hatırlatmaları) için gerekli
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Play Store'a ilk yüklemeden sonra DEĞİŞTİRİLEMEZ
        applicationId = "com.finanscepte.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystoreProperties.isNotEmpty()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Her zaman yükleme anahtarı: debug anahtarıyla imzalanan sürüm Play'e yüklenemez
            // ve telefondaki uygulamanın üzerine güncelleme olarak kurulamaz.
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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

// key.properties yoksa release derlemesi sessizce yanlış anahtarla değil, açık bir hatayla dursun
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

gradle.taskGraph.whenReady {
    if (keystoreProperties.isEmpty() && allTasks.any { it.name.contains("Release") }) {
        throw GradleException(
            "android/key.properties bulunamadı. Release sürümü yükleme anahtarıyla " +
            "(~/keystores/finanscepte-upload.jks) imzalanmalı; aksi halde güncelleme olarak kurulamaz."
        )
    }
}
