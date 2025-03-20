// build.gradle.kts (módulo app)
plugins {
    // No especifiques la versión para evitar conflictos con la que Flutter ya incluye
    id("com.android.application")

    // Plugin de Google Services (Firebase)
    id("com.google.gms.google-services")

    // Plugin de Kotlin para Android
    id("org.jetbrains.kotlin.android")

    // Plugin de Flutter (debe ir después de Android y Kotlin)
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.comerciofenix056.comercio_fenix_v1"

    // Estas propiedades se ajustan sin fijar la versión del plugin
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.comerciofenix056.comercio_fenix_v1"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17


    }
    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // Usa la firma de debug temporalmente si no tienes firma release
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
