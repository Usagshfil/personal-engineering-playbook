# 08. Secure Application Configuration & Mobile Hardening

---

## 1. Definition
**Secure Configuration** is the practice of locking down mobile build settings, operating system manifests, and network policies to ensure that application binaries are hardened against reverse-engineering, dynamic tampering, and insecure communication. In Android, this centers on **Network Security Config**, **Disabling Debug Flags in Release**, **ProGuard/R8 Obfuscation**, and **Disabling Insecure Backups**.

---

## 2. Purpose
Default mobile project templates are configured for developer convenience rather than security: they allow cleartext HTTP traffic, enable USB debugging, permit automated system backups of internal data, and output readable class and method names in decompiled code. Secure configuration replaces these insecure defaults with production-grade hardening.

---

## 3. Why It Matters
*   **Preventing Cleartext Traffic**: Android 9+ blocks cleartext HTTP by default. A broken configuration that bypasses this (`android:usesCleartextTraffic="true"`) exposes user logins to packet sniffing on public coffee-shop Wi-Fi.
*   **Android `allowBackup` Risk**: If `android:allowBackup="true"` is enabled in `AndroidManifest.xml`, an attacker with physical access to an unlocked phone can run `adb backup` and extract the app's entire SQLite database and private preferences over USB without root.
*   **R8 / ProGuard Obfuscation**: R8 shrinks binaries and renames classes and methods to cryptic symbols (`a.b.c()`), dramatically raising the effort required for an attacker to reverse-engineer proprietary algorithms.

---

## 4. When to Use It
*   **Every Production Build**: Verify hardening settings before generating any release APK or Android App Bundle (AAB).
*   **Android Manifest Auditing**: Ensure `debuggable="false"`, `allowBackup="false"`, and strict exported component flags.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Local Debug Builds**: Keep R8 obfuscation disabled in `debug` build types. Enabling full obfuscation during rapid local development slows down compilation times and breaks interactive line breakpoints in the Android Studio debugger.

---

## 6. Advantages & Disadvantages

| Hardened Production Configuration | Permissive Default Configuration |
| :--- | :--- |
| **Blocks Network Sniffing**: Strict HTTPS enforcement. | **Cleartext Leaks**: Passwords sniffable on public Wi-Fi. |
| **Prevents ADB Extraction**: Backups of private DBs blocked. | **Trivial Data Theft**: Entire DB dumped via USB in 10 seconds. |
| **Obfuscated Logic**: Class names scrambled against reverse engineering. | **Readable Decompilation**: Source code reconstructed effortlessly in `jadx`. |

---

## 7. Practical Examples

### Android Manifest Hardening (`AndroidManifest.xml`)
```xml
<application
    android:allowBackup="false"
    android:fullBackupContent="false"
    android:networkSecurityConfig="@xml/network_security_config"
    android:supportsRtl="true"
    android:theme="@style/Theme.App">

    <!-- Explicitly set exported="false" on all internal components -->
    <activity
        android:name=".feature.auth.InternalAuthActivity"
        android:exported="false" />

    <!-- Only the main launcher activity should be exported -->
    <activity
        android:name=".MainActivity"
        android:exported="true">
        <intent-filter>
            <action android:name="android.intent.action.MAIN" />
            <category android:name="android.intent.category.LAUNCHER" />
        </intent-filter>
    </activity>
</application>
```

### Strict Network Security Config (`res/xml/network_security_config.xml`)
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- Strictly disallow cleartext HTTP traffic across entire app -->
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
```

### Production Build Hardening in `build.gradle.kts`
```kotlin
android {
    buildTypes {
        release {
            isMinifyEnabled = true          // Enables R8 code shrinking and obfuscation
            isShrinkResources = true        // Removes unused resources
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            isMinifyEnabled = false         // Fast builds for local dev
            isDebuggable = true
        }
    }
}
```

---

## 8. Common Mistakes
1.  **Leaving `android:usesCleartextTraffic="true"`**: Allowing unencrypted HTTP connections across the application.
2.  **Exporting Internal Activities**: Forgetting `android:exported="false"` on internal activities, services, or broadcast receivers, allowing malicious third-party apps on the phone to invoke them directly.
3.  **Hardcoding Signing Passwords in Gradle**: Writing the keystore password directly in `build.gradle.kts` instead of pulling from environment variables.

---

## 9. Verification Checklist (OWASP MASVS-PLATFORM / MASVS-RESILIENCE)

- [ ] Is `android:allowBackup="false"` set in `AndroidManifest.xml` (unless encrypted backup is explicitly designed)?
- [ ] Is cleartext HTTP traffic strictly disabled via Network Security Config?
- [ ] Are internal Activities, Services, and Receivers marked with `android:exported="false"`?
- [ ] Is R8 code shrinking and obfuscation (`isMinifyEnabled = true`) enabled on release builds?
- [ ] Are release keystore credentials injected securely via environment variables or CI/CD secret vaults (never committed to version control)?
