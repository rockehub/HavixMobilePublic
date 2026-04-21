import java.util.Base64

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Decode --dart-define values passed by Flutter build
fun decodeDartDefines(): Map<String, String> {
    val raw = project.findProperty("dart-defines") as String? ?: return emptyMap()
    return raw.split(",").associate { entry ->
        val decoded = String(Base64.getDecoder().decode(entry))
        val idx = decoded.indexOf('=')
        decoded.substring(0, idx) to decoded.substring(idx + 1)
    }
}

val dartDefines = decodeDartDefines()
val tenantBundleId = dartDefines["BUNDLE_ID_ANDROID"] ?: "com.havix.store"
val tenantAppName = dartDefines["APP_NAME"] ?: "Havix Store"

// Load tenant keystore from key.properties if present (written by build_android.sh)
val keyPropertiesFile = rootProject.file("app/key.properties")
val keyProperties = java.util.Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(keyPropertiesFile.inputStream())
}

android {
    namespace = "com.havix.havix_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        if (keyPropertiesFile.exists()) {
            create("tenantRelease") {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = tenantBundleId
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "app_name", tenantAppName)
    }

    buildTypes {
        release {
            signingConfig = if (keyPropertiesFile.exists())
                signingConfigs.getByName("tenantRelease")
            else
                signingConfigs.getByName("debug")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
