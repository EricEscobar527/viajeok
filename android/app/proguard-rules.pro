# Release builds are shrunk with R8. Keep what is reached by reflection or
# from the Android framework so it isn't renamed or removed.

# ML Kit text recognition discovers its components by reflection; without
# these, TextRecognition.getClient() crashed with an NPE in release builds.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_bundled_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_common.** { *; }
-keep class com.google.android.gms.common.internal.** { *; }
-keep class com.google.firebase.components.** { *; }
-dontwarn com.google.mlkit.**

# Our accessibility service, overlay and parser (started by the system).
-keep class cloud.doublee.viajeok.** { *; }
