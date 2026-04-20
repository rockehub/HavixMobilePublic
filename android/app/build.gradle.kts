plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Decode --dart-define values passed by Flutter build
fun decodeDartDefines(): Map<String, String> {
    val raw = project.findProperty("dart-defines") as String? ?: return emptyMap()
    return raw.split(",").associate { entry ->
        val decoded = String(java.util.Base64.getDecoder().decode(entry))
        val idx = decoded.indexOf('=')
        decoded.substring(0, idx) to decoded.substring(idx + 1)
    }
}

val dartDefines = decodeDartDefines()
val tenantBundleId = dartDefines["BUNDLE_ID_ANDROID"] ?: "com.havix.store"
val tenantAppName = dartDefines["APP_NAME"] ?: "Havix Store"

android {
    namespace = "com.havix.havix_mobile"
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
        // applicationId is injected per-tenant via --dart-define=BUNDLE_ID_ANDROID=com.client.app
        applicationId = tenantBundleId
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // App name injected via --dart-define=APP_NAME=NomeDaLoja
        resValue("string", "app_name", tenantAppName)
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
