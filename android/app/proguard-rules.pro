# ProGuard rules for AuraList
# Keep this file even if it's empty, the build system needs it

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Hive
-keep class * extends com.hivedb.** { *; }
-keepclassmembers class * {
    @com.hivedb.** *;
}
-keep class com.hivedb.** { *; }

# Riverpod
-keep class * extends com.riverpod.** { *; }

# Models - Keep all model classes to prevent serialization issues
-keep class com.example.checklist_app.models.** { *; }
-keepclassmembers class com.example.checklist_app.models.** {
    *;
}

# Kotlin
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Package Info
-keep class io.flutter.plugins.packageinfo.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Connectivity Plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Crashlytics
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# General optimizations
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*
