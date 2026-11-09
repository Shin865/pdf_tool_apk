# Apache POI ProGuard rules for Spike A

# Keep POI classes
-keep class org.apache.poi.** { *; }
-keep class org.apache.xmlbeans.** { *; }
-keep class org.openxmlformats.** { *; }
-keep class com.microsoft.schemas.** { *; }
-keep class org.apache.commons.** { *; }

# Keep XML-related classes
-keep class javax.xml.** { *; }

# Don't warn about missing optional dependencies
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

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Suppress warnings from optional POI / XMLBeans transitive deps
-dontwarn com.github.javaparser.**
-dontwarn com.github.luben.zstd.**
-dontwarn com.google.android.play.**
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


