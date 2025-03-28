plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

val keyPropertiesFile = file("D:/Flutter Projects/Mershed/key.properties") // Absolute path
println("Looking for key.properties at: ${keyPropertiesFile.absolutePath}")
if (!keyPropertiesFile.exists()) {
    throw GradleException("key.properties file not found at ${keyPropertiesFile.absolutePath}. Ensure it is in D:\\Flutter Projects\\Mershed\\")
}

val keyProperties = Properties().apply {
    println("key.properties found, loading...")
    load(keyPropertiesFile.reader())
}

android {
    namespace = "com.example.mershed"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.mershed"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties.getProperty("keyAlias") ?: throw GradleException("keyAlias not found in key.properties")
            keyPassword = keyProperties.getProperty("keyPassword") ?: throw GradleException("keyPassword not found in key.properties")
            storeFile = file("D:/Flutter Projects/Mershed/android/my-keystore.jks") // Absolute path
            storePassword = keyProperties.getProperty("storePassword") ?: throw GradleException("storePassword not found in key.properties")
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("debug") {}
    }
}

dependencies {
    implementation("com.google.android.gms:play-services-auth:20.7.0")
}

flutter {
    source = "../.."
}