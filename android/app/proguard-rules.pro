# ==============================================================================
# Flutter ProGuard / R8 Rules
# ==============================================================================

# Flutter Wrapper & Framework
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Generated Plugin Registrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Keep native methods (JNI callbacks)
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve general reflection and annotation attributes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes Deprecated
-keepattributes SourceFile,LineNumberTable

# Preserve Flutter embedding warnings
-dontwarn io.flutter.embedding.**

# Keep enum methods for Dart <-> Java/Kotlin interop
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Preserve Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    !private <fields>;
    !private <methods>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Kotlin companion objects
-keepclassmembers class * {
    public static ** Companion;
}

# SQLite / Drift support (sqlite3_flutter_libs)
-keep class com.russhwolf.sqlite3.** { *; }
-dontwarn com.russhwolf.sqlite3.**
-keep class org.sqlite.** { *; }
-dontwarn org.sqlite.**

# Google Play splitcompat optional
-dontwarn com.google.android.play.**

# Apache POI & XMLBeans
-keep class org.apache.poi.** { *; }
-keep class org.apache.xmlbeans.** { *; }
-keep class org.openxmlformats.** { *; }
-keep class com.microsoft.schemas.** { *; }
-keep class org.apache.commons.** { *; }
-keep class javax.xml.** { *; }

-dontwarn org.apache.batik.**
-dontwarn org.apache.fontbox.**
-dontwarn org.apache.pdfbox.**
-dontwarn org.bouncycastle.**
-dontwarn org.etsi.**
-dontwarn org.openxmlformats.**
-dontwarn com.microsoft.**
-dontwarn org.w3.**
-dontwarn javax.xml.**
-dontwarn org.apache.logging.**
-dontwarn org.apache.commons.logging.**
-dontwarn de.rototor.**
-dontwarn com.zaxxer.**
-dontwarn org.apache.poi.sl.**
-dontwarn org.apache.poi.xslf.**
-dontwarn org.apache.poi.hslf.**
-dontwarn org.apache.poi.xdgf.**
-dontwarn java.awt.**

-dontwarn com.github.javaparser.**
-dontwarn com.github.luben.zstd.**
-dontwarn com.sun.org.apache.**
-dontwarn java.lang.invoke.MethodHandleProxies
-dontwarn javax.imageio.**
-dontwarn javax.swing.**
-dontwarn net.sf.saxon.**
-dontwarn org.apache.jcp.**
-dontwarn org.apache.maven.**
-dontwarn org.apache.tools.ant.**
-dontwarn org.apache.xml.security.**
-dontwarn org.brotli.**
-dontwarn org.ietf.jgss.**
-dontwarn org.objectweb.asm.**
-dontwarn org.tukaani.xz.**
-dontwarn org.w3c.dom.**

# PdfBox-Android
-keep class com.tom_roush.pdfbox.** { *; }
-keep class com.tom_roush.fontbox.** { *; }
-dontwarn com.tom_roush.pdfbox.**
-dontwarn com.tom_roush.fontbox.**

# Document Reviewer Native Bridge & Engines
-keep class com.example.documentreviewer.** { *; }

# AndroidX Biometric & Security
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# OpenCV & Tesseract (Offline Scanning & OCR)
-keep class org.opencv.** { *; }
-dontwarn org.opencv.**
-keep class com.googlecode.tesseract.android.** { *; }
-dontwarn com.googlecode.tesseract.android.**



