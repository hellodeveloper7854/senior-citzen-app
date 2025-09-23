# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter
-keep class io.flutter.** { *; }
-keep class com.google.gson.** { *; }
-keep class com.google.protobuf.** { *; }

# Supabase
-keep class io.supabase.** { *; }
-keep class com.supabase.** { *; }
-keep class org.postgresql.** { *; }
-keep class io.github.jan.supabase.** { *; }

# OkHttp
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Retrofit (if used)
-keep class retrofit2.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Keep data class members
-keepclassmembers class * extends kotlin.coroutines.Continuation {
    <fields>;
}
-keepclassmembers class kotlin.coroutines.Continuation {
    <fields>;
}

# Keep all classes that might be used via reflection
-keep class * implements java.io.Serializable { *; }
-keep class * extends java.lang.Exception { *; }

# General keep for classes with @Keep annotation
-keep @android.support.annotation.Keep class *
-keep @androidx.annotation.Keep class *

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum values and methods
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Cryptography/Tink
-keep class com.google.crypto.tink.** { *; }
-keep class org.bouncycastle.** { *; }

# Keep all classes in your package
-keep class com.example.aadharwad.** { *; }