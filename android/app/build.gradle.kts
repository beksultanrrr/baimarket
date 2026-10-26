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
        // Реальный пол — 24: столько объявляет FlutterExtension.minSdkVersion
        // текущего Flutter, и ровно столько требует video_player_android.
        // flutter_webrtc (livekit_client) довольствуется 21, поэтому клэмп
        // ниже 24 опускать нельзя — сборка отвалится на video_player.
        minSdk = maxOf(flutter.minSdkVersion, 24)
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

// Версия firebase-messaging здесь не пиннится: её задаёт BoM, который
// подтягивает сам плагин firebase_messaging. Ручной пин 23.4.1 конфликтовал
// с ним и мог разъехаться при обновлении плагина.
//
// Плагин google-services применяется один раз в блоке plugins {} выше;
// повторный apply(plugin = ...) отсюда убран как дубль.
