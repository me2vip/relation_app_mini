plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mini.relation_app_mini"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.mini.relation_app_mini"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0.0"
    }

    signingConfigs {
        getByName("debug") {}
        create("release") {
            if (project.hasProperty("ANDROID_KEYSTORE_PATH") &&
                project.property("ANDROID_KEYSTORE_PATH").toString().isNotEmpty()) {
                keyAlias = project.property("ANDROID_KEY_ALIAS").toString()
                keyPassword = project.property("ANDROID_KEY_PASSWORD").toString()
                storeFile = file(project.property("ANDROID_KEYSTORE_PATH").toString())
                storePassword = project.property("ANDROID_STORE_PASSWORD").toString()
            }
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            signingConfig = if (project.hasProperty("ANDROID_KEYSTORE_PATH") &&
                project.property("ANDROID_KEYSTORE_PATH").toString().isNotEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
