# Flutter-specific rules
-keep class io.flutter.** { *; }
-keep class com.adhar.** { *; }

# Supabase rules
-keep class com.supabase.** { *; }
-keep class io.supabase.** { *; }

# Google Maps rules
-keep class com.google.android.gms.** { *; }
-keep class com.google.maps.** { *; }

# URL Launcher rules
-keep class io.flutter.plugins.urllauncher.** { *; }

# Permission Handler rules
-keep class com.baseflow.permissionhandler.** { *; }

# Location services rules
-keep class com.baseflow.geolocator.** { *; }

# Local Notifications rules
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Image Picker rules
-keep class io.flutter.plugins.imagepicker.** { *; }

# Secure Storage rules
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Record plugin rules
-keep class com.llfbandit.record.** { *; }

# Cryptography rules
-keep class dev.dart.cryptography.** { *; }

# Shared Preferences rules
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Path Provider rules
-keep class io.flutter.plugins.pathprovider.** { *; }

# Kotlin reflection
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keepclasseswithmembers class * {
    native <methods>;
}

# Keep all classes in the main package
-keep class com.adhar.adharvad.** { *; }

# Keep all enums
-keepclassmembers enum * { *; }

# Keep all serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Preserve all annotations
-keepattributes *Annotation*

# Preserve all source file and line number information for debugging
-keepattributes SourceFile,LineNumberTable

# Preserve all signatures
-keepattributes Signature

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# Google Play Core rules to fix R8 build errors
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task