import java.io.File
import java.util.Properties

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
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.mini.relation_app_mini"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        getByName("debug") {}
        create("release") {
            // 签名参数来源优先级：
            // 1. android/key.properties 文件（Flutter 官方推荐，CI 生成）
            // 2. -P 命令行参数 / ORG_GRADLE_PROJECT_ 环境变量
            val keystorePropertiesFile = rootProject.file("key.properties")
            val keystoreProperties = Properties()
            if (keystorePropertiesFile.exists()) {
                keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
            }
            fun prop(name: String): String {
                val fromFile = keystoreProperties.getProperty(name)
                if (!fromFile.isNullOrBlank()) return fromFile
                if (project.hasProperty(name)) {
                    return project.property(name).toString()
                }
                return ""
            }
            val storePath = prop("storeFile")
            val keyAliasName = prop("keyAlias")
            val storePass = prop("storePassword")
            val keyPass = prop("keyPassword")
            if (storePath.isNotBlank() && keyAliasName.isNotBlank() &&
                storePass.isNotBlank() && keyPass.isNotBlank()) {
                keyAlias = keyAliasName
                keyPassword = keyPass
                // storeFile 相对路径按 key.properties 所在目录（android/）解析；
                // 绝对路径（如 CI 传入的 ANDROID_KEYSTORE_PATH）直接使用。
                val storeFileObj = File(storePath)
                storeFile = if (storeFileObj.isAbsolute) {
                    storeFileObj
                } else {
                    File(keystorePropertiesFile.parentFile, storePath)
                }
                storePassword = storePass
            }
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            val releaseSigning = signingConfigs.getByName("release")
            signingConfig = if (releaseSigning.storeFile != null) {
                releaseSigning
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

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
