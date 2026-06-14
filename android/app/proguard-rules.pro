# ============================================================================
# Reguli ProGuard / R8 pentru build-ul de release (Block Smile / Tetris).
# isMinifyEnabled=true elimina clase accesate prin reflexie de plugin-uri.
# Regulile de mai jos pastreaza clasele de care au nevoie plugin-urile.
# Folosim proguard-android.txt (NU -optimize) ca sa evitam inline/merge agresiv.
# ============================================================================

# ---- Flutter engine + plugin registrant ----
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ---- Entry point-ul aplicatiei ----
-keep class ro.summersmile.tetrisclassic.** { *; }

# ---- Google Mobile Ads (google_mobile_ads) ----
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.ads.**

# ---- in_app_purchase / Google Play Billing ----
-keep class com.android.billingclient.** { *; }
-keep class com.android.vending.billing.** { *; }
-keep class io.flutter.plugins.inapppurchase.** { *; }
-dontwarn com.android.billingclient.**

# ---- in_app_review ----
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ---- Gson / atribute reflexie ----
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses,EnclosingMethod
-keep class com.google.gson.** { *; }
-keepclassmembers enum * { *; }

# ---- Kotlin metadata (unele plugin-uri o folosesc la runtime) ----
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**
