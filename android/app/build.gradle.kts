plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.aapkakaam.app"

    // Google Play requires API 36
    compileSdk = 36

    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "com.aapkakaam.app"

        minSdk = 23
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"]?.toString()
            keyPassword = keystoreProperties["keyPassword"]?.toString()

            storeFile = file(
                keystoreProperties["storeFile"]?.toString()
            )

            storePassword = keystoreProperties["storePassword"]?.toString()
        }
    }

    buildTypes {
        getByName("release") {

            // Enable code shrinking
            isMinifyEnabled = true
            isShrinkResources = false

            // Release signing
            signingConfig = signingConfigs.getByName("release")

            // Native debug symbols for Google Play Console
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }

            proguardFiles(
                getDefaultProguardFile(
                    "proguard-android-optimize.txt"
                ),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {

    coreLibraryDesugaring(
        "com.android.tools:desugar_jdk_libs:2.1.4"
    )

    implementation(
        platform("com.google.firebase:firebase-bom:33.13.0")
    )

    implementation("com.google.firebase:firebase-analytics")

    implementation("com.google.firebase:firebase-messaging")
}