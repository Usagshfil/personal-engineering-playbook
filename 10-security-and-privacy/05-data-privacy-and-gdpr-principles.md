# 05. Data Privacy, Minimization & GDPR Engineering Principles

---

## 1. Definition
**Data Privacy Engineering** is the technical practice of designing software systems to protect personal user data in accordance with privacy laws (such as GDPR, CCPA, and COPPA). Its core pillars are **Data Minimization** (collecting only the minimum data strictly necessary), **Purpose Limitation** (using data only for its stated purpose), **Privacy by Default**, and **The Right to Erasure (Deletion)**.

---

## 2. Purpose
Collecting excessive personal user data creates severe legal liability, increases regulatory breach fines, and harms user trust. The purpose of data privacy engineering is to protect the user's fundamental right to digital privacy while ensuring the software complies with global data protection mandates.

---

## 3. Why It Matters
*   **Data Minimization Reduces Breach Impact**: You cannot lose or leak data that you never collected. If your app only needs to know an order total, do not collect the user's precise GPS coordinates or birthday.
*   **App Store Approvals**: Google Play requires explicit Data Safety declarations. If your app requests camera, location, or contact permissions without a clear, documented in-app purpose, Google will reject or delist the application.
*   **Account Deletion Mandate**: Modern app store guidelines mandate that any app allowing user account creation **must also provide a self-service way to delete the account and all associated personal data**.

---

## 4. When to Use It
*   **Every App Collecting User Data**: Any system that handles names, emails, IP addresses, location data, or device identifiers.
*   **Runtime Permission Requests**: Request mobile runtime permissions (Camera, Location, Notifications) **in context**—only at the exact moment the user taps a feature requiring that capability, accompanied by an explanation.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Paranoid Avoidance of Essential Operational Data**: Do not refuse to store an order address in an e-commerce checkout flow under the guise of "data minimization." Data strictly required to execute a contract or fulfill an order is legally justified and necessary.

---

## 6. Advantages & Disadvantages

| Privacy by Design & Minimization | Hoarding All Possible User Telemetry |
| :--- | :--- |
| **Minimal Breach Liability**: Lower risk surface during a breach. | **Massive Regulatory Fines**: Millions in GDPR/CCPA penalties. |
| **High User Trust & Conversion**: Users appreciate transparent privacy. | **User Churn**: Users uninstall apps asking for invasive permissions. |
| **Faster App Store Approvals**: Smooth Google Play Data Safety reviews. | **App Store Rejections**: Rejected for unjustified background access. |

---

## 7. Practical Examples

### In-Context Runtime Permission Request in Jetpack Compose
```kotlin
// GOOD: Request permission only when the user explicitly triggers the action, with clear rationale
@Composable
fun ScanReceiptScreen(
    onNavigateToCamera: () -> Unit
) {
    val cameraPermissionState = rememberPermissionState(Manifest.permission.CAMERA)

    Column(modifier = Modifier.padding(16.dp)) {
        Text("Scan Expense Receipt", style = MaterialTheme.typography.titleLarge)
        
        if (cameraPermissionState.status.isGranted) {
            Button(onClick = onNavigateToCamera) {
                Text("Open Camera")
            }
        } else {
            Card(modifier = Modifier.padding(vertical = 8.dp)) {
                Text("Camera permission is needed exclusively to photograph receipts and extract totals.")
            }
            Button(onClick = { cameraPermissionState.launchPermissionRequest() }) {
                Text("Grant Camera Access")
            }
        }
    }
}
```

### Self-Service Account & Data Deletion Flow (Repository Level)
```kotlin
interface UserAccountRepository {
    /**
     * Executes GDPR Article 17 "Right to Erasure".
     * Purges remote backend records, local Room database, and encrypted keystore tokens.
     */
    suspend fun deleteAccountAndAllUserData(): Result<Unit>
}
```

---

## 8. Common Mistakes
1.  **Requesting All Permissions on App Launch**: Asking for Camera, Location, Contacts, and Microphone the very first second the user opens the app before they even see a screen.
2.  **Tracking Users Across Apps without Consent**: Using advertising IDs or device fingerprints without explicit user opt-in consent.
3.  **Missing Data Deletion Endpoint**: Providing a "Sign Up" button, but forcing users to email support manually to delete their account.

---

## 9. Verification Checklist

- [ ] Does the app collect only the absolute minimum data necessary to function?
- [ ] Are mobile runtime permissions requested in context with user-facing rationale?
- [ ] Is an automated self-service account and data deletion mechanism provided?
- [ ] Does the Google Play Data Safety declaration accurately reflect actual code telemetry?
- [ ] Is personal user data encrypted both in transit (TLS) and at rest (Room with SQLCipher or EncryptedSharedPreferences)?
