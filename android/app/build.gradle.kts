plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.tobuy"
    compileSdk = 35
    ndkVersion = "29.0.13113456" // Version NDK stable compatible avec compileSdk 34

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.tobuy"
        minSdk = 26 // Entier, sans guillemets
        targetSdk = 35
        versionCode = 1 // Valeur fixe pour simplifier
        versionName = "1.0" // Valeur fixe pour simplifier
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.0.21")
}