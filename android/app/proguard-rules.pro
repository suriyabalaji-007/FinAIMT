# Flutter Proguard Rules

# Preserve Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Preserve Google Fonts/Outift
-keep class com.google.fonts.** { *; }

# Preserve specialized plugins
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.stripe.android.** { *; }

# General Proguard rules
-dontwarn io.flutter.embedding.android.FlutterActivity
-dontwarn io.flutter.embedding.android.FlutterFragment
-dontwarn io.flutter.embedding.android.FlutterView
