# 11. Android Release Engineering, App Store Deployment & CI/CD: Keystore, R8/ProGuard & Staged Rollouts

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Domain**: Android & Kotlin Development  
> **Target Version**: Gradle 8+, Android Gradle Plugin 8.4+, Google Play Developer API, Fastlane 2.220+

---

## 1. Definition & Core Concept

**Android Release Engineering** is the disciplined discipline of converting verified source code into an optimized, obfuscated, and cryptographically signed **Android App Bundle (.aab)**, followed by automated distribution through progressive deployment tracks to the Google Play Store.

```
+---------------------------------------------------------------------------------------------------+
|                                ANDROID CI/CD RELEASE PIPELINE                                     |
|                                                                                                   |
|  [Git release/* or hotfix/* Branch]                                                               |
|         │                                                                                         |
|         ▼                                                                                         |
|  [GitHub Actions Runner]                                                                          |
|         │                                                                                         |
|         ├─── 1. Run Verification ─────► [JVM Unit Tests & Roborazzi Screenshot Checks]            |
|         │                                                                                         |
|         ├─── 2. Compile & Shrink ──────► [R8 Full Mode (Bytecode Optimization & Obfuscation)]     |
|         │                                                                                         |
|         ├─── 3. Sign AAB ──────────────► [Android Keystore (Injected via CI Secrets / Base64)]    |
|         │                                                                                         |
|         ├─── 4. Archive Artifacts ────► [AAB Binary + ProGuard mapping.txt]                       |
|         │                                                                                         |
|         ▼                                                                                         |
|  [Fastlane Lane (supply)]                                                                         |
|         │                                                                                         |
|         ├─── 5. Deploy Internal ──────► [Google Play Internal Track (QA / Smoke Validation)]       |
|         │                                                                                         |
|         └─── 6. Staged Rollout ────────► [Production (1% ──► 5% ──► 20% ──► 100%)]                |
+---------------------------------------------------------------------------------------------------+
```

### Key Architectural Pillars
1.  **Android App Bundle (AAB)**: The publishing format that defers APK generation to Google Play, delivering only the device-specific CPU architecture (ARM64/x86), language resources, and screen densities required by the user's hardware.
2.  **R8 Code & Resource Shrinking**: Removes unused classes, fields, and methods (tree-shaking), optimizes bytecode instructions, and obfuscates identifiers (`a.b.c`) to protect proprietary logic and reduce download size.
3.  **Two-Tier Cryptographic Signing**: 
    *   *Upload Key*: Maintained in secure CI secrets, used by the team to authenticate AAB uploads to Google Play.
    *   *Google Play App Signing Key*: Managed in Google's secure infrastructure to sign device-delivered APKs.
4.  **Progressive Staged Rollout**: Incrementally releasing updates to fractions of the production audience (e.g. 1% $\to$ 5% $\to$ 20% $\to$ 100%), monitoring crash-free user rates at each gate.

---

## 2. Purpose

The purpose of this standard is to eliminate manual deployment errors, guarantee binary tampering defenses, minimize app download sizes to maximize conversion rates, and prevent widespread production outages through staged rollouts and automated mapping file archival.

---

## 3. Why It Matters

*   **Conversion Rate vs. App Size**: Industry empirical research demonstrates that every 6MB increase in app size decreases store installation conversion by $\sim 1\%$. R8 shrinking and AAB distribution reduce binary size by $30\% - 60\%$.
*   **Tamper Resistance & Intellectual Property**: An un-obfuscated Android binary can be decompiled into human-readable Java in seconds using tools like `jadx`. Obfuscation raises the cost of reverse engineering.
*   **Catastrophic Keystore Loss**: Hardcoding keystore passwords in version control leaks publishing authority. Conversely, losing a non-backed-up release keystore permanently locks developers out of updating existing users.
*   **Crash Rate Defense**: Releasing directly to 100% of users risks deploying an edge-case crash to the entire user base. Staged rollouts provide a monitoring window to halt releases before widespread impact.

---

## 4. When to Use It

*   **All Production & Staging Releases**: Mandatory for all internal, beta, and production distribution builds.
*   **Release Freezes (`release/*` branches)**: Triggered during the sprint stabilization phase under [Gitflow](../../05-skills/git-and-version-control/SKILL.md).
*   **Emergency Production Hotfixes (`hotfix/*` branches)**: Used for time-critical defect resolution directly targeted at `main`.

---

## 5. When NOT to Use It

*   **Local Developer Iteration**: Do not run full R8 shrinking and AAB packaging during local incremental testing. Running R8 on every build adds 30–90 seconds of compilation overhead.
*   **Internal Development Testing on Emulators**: Use standard debug APK builds with `minSdk = 26` to enable fast incremental dexing.

---

## 6. Advantages & Disadvantages

| Release Strategy | Pros | Cons |
| :--- | :--- | :--- |
| **Android App Bundle (AAB)** | **$30\% - 60\%$ smaller download size**; dynamic feature modules. | Cannot be installed directly on a device via `adb` without `bundletool`. |
| **R8 Full Mode** | Maximum dead code elimination; aggressive bytecode optimization. | Requires precise `-keep` rules for reflection and serialization models. |
| **Automated Fastlane Deployment** | 1-command reproducible releases; eliminates manual console errors. | Requires initial service account JSON key configuration in Google Play. |
| **Staged Rollouts (1% $\to$ 100%)** | Early blast-radius containment; allows halting bad releases. | Takes 3–7 days to reach full audience adoption. |

---

## 7. Practical Examples

### 7.1 Secure Gradle Signing Configuration (Environment Secrets)

```kotlin
// app/build.gradle.kts
import java.io.File
import java.util.Base64

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.serialization)
}

android {
    namespace = "com.personal.playbook.app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.personal.playbook.app"
        minSdk = 24
        targetSdk = 34
        versionCode = (System.getenv("BUILD_NUMBER") ?: "1").toInt()
        versionName = "1.0.0"
    }

    signingConfigs {
        create("release") {
            // Read credentials exclusively from environment variables (Tier 1 Rule 7)
            val keystoreBase64 = System.getenv("ANDROID_KEYSTORE_BASE64")
            val keystoreFile = File(layout.buildDirectory.asFile.get(), "release.keystore")

            if (!keystoreBase64.isNullOrEmpty()) {
                keystoreFile.writeBytes(Base64.getDecoder().decode(keystoreBase64))
                storeFile = keystoreFile
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            isMinifyEnabled = false
            applicationIdSuffix = ".debug"
        }
    }
}
```

### 7.2 Production R8 / ProGuard Configuration

```proguard
# app/proguard-rules.pro

# 1. Preserve Kotlinx Serialization models from member stripping
-keepattributes *Annotation*, InnerClasses, Signature
-keepclassmembers class * {
    @kotlinx.serialization.SerialName <fields>;
}
-keep,allowobfuscation,allowshrinking @kotlinx.serialization.Serializable class *

# 2. Preserve Room Database & DAO interfaces
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Dao interface * { *; }
-keep @androidx.room.Entity class * { *; }

# 3. Preserve Retrofit API Interfaces and HTTP Annotations
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations
-keepclassmembers,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}

# 4. Strip sensitive logging in release builds (Tier 1 Rule 7 defense-in-depth)
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

# 5. Retain line numbers for de-obfuscation in Crashlytics
-keepattributes SourceFile, LineNumberTable
-renamesourcefileattribute SourceFile
```

### 7.3 Automated Fastlane Deployment Lane (`Fastfile`)

```ruby
# fastlane/Fastfile
default_platform(:android)

platform :android do
  desc "Deploy Release AAB to Google Play Internal Testing Track"
  lane :internal do
    # 1. Run JVM Unit tests and lint
    gradle(task: "testReleaseUnitTest")
    gradle(task: "lintRelease")

    # 2. Build signed production AAB
    gradle(
      task: "bundleRelease"
    )

    # 3. Upload AAB and de-obfuscation mapping file to Google Play
    upload_to_play_store(
      track: "internal",
      aab: "app/build/outputs/bundle/release/app-release.aab",
      mapping_paths: ["app/build/outputs/mapping/release/mapping.txt"],
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end

  desc "Promote Internal build to Staged Production Rollout (10%)"
  lane :promote_to_production do
    upload_to_play_store(
      track: "internal",
      track_promote_to: "production",
      rollout: "0.10" # 10% initial production staged rollout
    )
  end
end
```

---

## 8. Common Mistakes & Pitfalls

1.  **Committing Keystores or Passwords to Source Control**:
    *   *Problem*: Committing `.keystore` or `.jks` files or writing passwords directly inside `build.gradle.kts` permanently leaks credentials to anyone with read access to the repository.
    *   *Remedy*: Inject keystores as base64-encoded GitHub Secrets or retrieve them from cloud key management services (AWS KMS, Google Cloud Secret Manager).
2.  **Missing Keep Rules for Serialized Models**:
    *   *Problem*: R8 strips or renames fields on data classes that are serialized/deserialized via reflection. The app works in debug mode, but immediately crashes in production with `NullPointerException` or missing JSON fields.
    *   *Remedy*: Always configure explicit `-keep` rules for all `@Serializable` and `@Entity` data classes, and run automated smoke tests against release builds in CI.
3.  **Failing to Archive `mapping.txt` De-Obfuscation Files**:
    *   *Problem*: Releasing an obfuscated app without storing the build-specific `mapping.txt` means crash stack traces in Firebase Crashlytics or Google Play Console appear as unreadable symbols (`at a.b.c.d(Unknown Source)`).
    *   *Remedy*: Automatically upload `mapping.txt` via Fastlane or CI artifacts on every release build.
4.  **Deploying Directly to 100% Production**:
    *   *Problem*: Pushing an update directly to 100% of production users causes widespread outage if a device-specific OEM bug (e.g. Samsung OneUI or Xiaomi MIUI background constraint) was missed in testing.
    *   *Remedy*: Always follow progressive staged rollouts: 1% (24 hours) $\to$ 10% (24 hours) $\to$ 50% $\to$ 100%.

---

## 9. Verification Checklist

- [ ] Are keystore files and passwords retrieved exclusively from CI environment variables (never committed)?
- [ ] Is `isMinifyEnabled = true` and `isShrinkResources = true` enabled on the release build type?
- [ ] Are serialization models (`@Serializable`), Room entities, and Retrofit interfaces protected in `proguard-rules.pro`?
- [ ] Does R8 strip raw `Log.d` and `Log.v` statements from production binaries?
- [ ] Are line numbers and source file attributes preserved for Crashlytics de-obfuscation?
- [ ] Are `mapping.txt` files archived as build artifacts and uploaded to Google Play Console?
- [ ] Are production releases managed through automated progressive staged rollouts (1% $\to$ 10% $\to$ 100%)?
- [ ] Is the app published as an Android App Bundle (.aab) rather than a monolithic APK?
