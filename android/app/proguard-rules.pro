# Keep ML Kit OCR classes used by google_mlkit_text_recognition
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

# Keep Play Core / deferred component classes used by Flutter Android embedding
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }

# Keep general Android/Flutter plugin classes
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.embedding.** { *; }

# Prevent warnings from being treated as fatal for ML Kit / Play Core
-dontwarn com.google.mlkit.vision.text.**
-dontwarn com.google.android.play.core.**
