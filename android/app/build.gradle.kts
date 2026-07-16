import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") // <-- уже есть
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Загружаем upload-ключ из android/key.properties.
// Файл не коммитится в git — см. .gitignore.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.bmarket.baimarket"
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
        applicationId = "com.bmarket.baimarket"
        // flutter_webrtc (livekit_client) требует minSdk >= 21.
        minSdk = maxOf(flutter.minSdkVersion, 21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFileName = keystoreProperties["storeFile"] as String?
            if (storeFileName != null) {
                // Путь резолвим относительно android/ (rootProject),
                // т.к. сам keystore лежит в android/upload-keystore.jks,
                // а не в android/app/.
                storeFile = rootProject.file(storeFileName)
            }
            storePassword = keystoreProperties["storePassword"] as String?
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
        }
    }

    buildTypes {
        release {
            // Подписываем upload-ключом из key.properties. Если файла нет
            // (CI без секретов или клонированный репо) — fallback на debug,
            // чтобы локальная сборка не падала.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

// ✅ Добавить зависимости для Firebase Messaging
dependencies {
    implementation("com.google.firebase:firebase-messaging:23.4.1")
}

// ✅ Эта строка обязательно должна идти в конце!
apply(plugin = "com.google.gms.google-services")
