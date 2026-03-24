# Kheteebaadi ProGuard Rules
# Keep Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Razorpay (payment SDK)
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-optimizations !method/inlining/*

# Keep Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Keep Speech-to-Text
-keep class com.csdcorp.speech_to_text.** { *; }

# Keep Google Play Services (for location)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# General
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-dontwarn java.nio.file.*
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
