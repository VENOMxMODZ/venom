# DefineAura iOS Authentication & Floating UI System

A modular, production-ready authentication and floating UI overlay system for iOS applications and injected dynamic libraries (`.dylib`).

---

## Overview

* **Application Name:** Define Aura (`DefineAura`)
* **API Endpoint:** `https://venompanel.shop/rootapi`
* **Target OS:** iOS 14.0+
* **Architectures:** `arm64`, `arm64e`

---

## Key Features

1. **Professional Dark Login UI (`LoginViewController`)**
   - Sleek dark slate glassmorphism theme (`#0B0F19`, `#161E2E`).
   - Branded "DA" badge and "Define Aura" typography.
   - Text field with clipboard paste support and cached key auto-fill.
   - Animated status/error banner with color feedback.
   - Smooth animated exit transition (scale & fade) upon authorization.

2. **Categorized Error & Status Handling**
   - **`AuthStatusSuccess`:** Verifies license, launches module, stores session in Keychain, transitions to floating UI.
   - **`AuthStatusInvalidKey`:** Informs user that the key was not found or is unauthorized.
   - **`AuthStatusExpiredKey`:** Detects subscription expiration and prompts key renewal.
   - **`AuthStatusNetworkError`:** Handles timeouts, DNS drops, and offline states without crashing.
   - **`AuthStatusServerError`:** Handles HTTP 5xx or ill-formed JSON responses gracefully.

3. **Compact Draggable Floating UI (`FloatingView` & `FloatingController`)**
   - **Completely Hidden Before Authentication:** The floating overlay is never displayed until the license key is verified.
   - **Touch Pass-Through Overlay:** Built using a custom `UIWindow` (`FloatingOverlayWindow`) with touch forwarding (`hitTest:`), ensuring taps outside the floating button pass uninterrupted to the host game/application.
   - **Minimized State:** Small circular 52x52 badge with live status dot. Snaps to screen edges.
   - **Expanded State:** Compact 240x260 card with module state toggle, action button, session expiry details, and logout option.
   - **Gesture Support:** Fluid dragging with automatic safe-area boundary clamping.

4. **Hardware & Keychain Security (`SessionManager`)**
   - Uses native iOS Keychain Services (`Security.framework`) via `kSecClassGenericPassword` with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
   - Anchors a persistent unique device identifier across app reinstalls.
   - Stores user license key, session token, and expiry date securely.
   - **Zero Embedded Server Secrets:** Client only sends the public authentication payload without embedding private administrative keys.

5. **Military-Grade Anti-Crack & Anti-Tamper Engine (`SecurityHardening`)**
   - **Zero Plaintext Strings / Web Links:** The server endpoint (`venompanel.shop`), game identifier, request parameter names, headers, and security paths are compiled as encrypted byte arrays (`Obfuscation.h`) decoded ephemerally in RAM.
   - **Strict SSL / TLS Pinning:** Custom `NSURLSessionDelegate` verifying host identity and root certificates, blocking MITM proxy tools (Burp Suite, Charles Proxy, Mitmproxy).
   - **Dynamic Anti-Debugging (`ptrace` + `sysctl`):** Denies debugger attachment (`PT_DENY_ATTACH`) via dynamic symbol resolution and inspects `P_TRACED` proc flags.
   - **Anti-Frida & Injected Dylib Scanner:** Inspects loaded Mach-O images via `_dyld_image_count()` for Frida (`FridaGadget`, `frida-agent`), Cycript, Substrate, Substitute, and scans local Frida debug ports (27042).
   - **Continuous Sentinel Watchdog Thread:** Spawns a background sentinel thread running randomized interval checks that trigger immediate silent hardware traps (`__builtin_trap()`) upon detecting tampering.
   - **Cryptographic Server Session Canary ("Only My Server Can Login"):** Prevents local bypasses and hook-based spoofing (`isAuthorized = YES`). Native module actions verify a 64-bit cryptographic canary issued strictly upon legitimate server response validation.

6. **Clean Separation of Concerns (`ModuleInterface`)**
   - Decoupled native module interface.
   - Keeps business/payload logic strictly independent from UI and network code.
   - Automatically booted upon successful login (`startModuleWithSessionToken:licenseKey:expiryDate:`) and terminated upon logout (`stopModule`).

---

## Project Structure

```
ios login page dylib/
├── include/                     # Objective-C Public Headers
│   ├── Obfuscation.h            # Compile-time encrypted string data & decoders
│   ├── SecurityHardening.h      # Anti-crack, anti-debug, and canary engine
│   ├── APIClient.h              # HTTPS networking & TLS certificate verification
│   ├── SessionManager.h         # Keychain secure storage & device ID
│   ├── LoginManager.h           # Authentication flow orchestration
│   ├── LoginViewController.h    # Dark login UI controller
│   ├── FloatingView.h           # Draggable floating button & panel
│   ├── FloatingController.h     # Overlay window & touch pass-through
│   └── ModuleInterface.h        # Decoupled authorized module interface
├── src/                         # Objective-C Implementation Files (.m)
│   ├── SecurityHardening.m      # Anti-debug, anti-Frida, sentinel thread, canaries
│   ├── APIClient.m
│   ├── SessionManager.m
│   ├── LoginManager.m
│   ├── LoginViewController.m
│   ├── FloatingView.m
│   ├── FloatingController.m
│   ├── ModuleInterface.m
│   └── DylibEntry.m             # __attribute__((constructor)) dylib loader
├── swift/                       # Pure Swift Implementations
│   ├── SecurityHardening.swift  # Swift anti-crack sentinel & obfuscation
│   ├── APIClient.swift
│   ├── SessionManager.swift
│   ├── LoginManager.swift
│   ├── LoginViewController.swift
│   ├── FloatingView.swift
│   ├── FloatingController.swift
│   └── ModuleInterface.swift
├── tools/
│   └── generate_obfuscated_keys.py # String encryption generator
├── Makefile                     # Hardened build script for iOS arm64 dylib (-O3, -fvisibility=hidden, strip -x)
└── README.md                    # System documentation
```

---

## Authentication Flow

```
+-------------------------------------------------------------+
|                     Host App Launches                       |
+-------------------------------------------------------------+
                               |
                               v
               [DylibEntry / Constructor executes]
                               |
                               v
            +------------------------------------+
            | Present LoginViewController        |
            | (Floating UI remains HIDDEN)       |
            +------------------------------------+
                               |
                  [User enters license key]
                               |
                               v
            +------------------------------------+
            | LoginManager -> APIClient          |
            | POST https://venompanel.shop/rootapi|
            +------------------------------------+
                               |
          +--------------------+--------------------+
          |                                         |
     [Auth Failed]                             [Auth Success]
          |                                         |
          v                                         v
+-------------------------+             +--------------------------+
| Display status banner:  |             | 1. Save to Keychain      |
| - Invalid Key           |             | 2. Boot ModuleInterface  |
| - Expired Key           |             | 3. Dismiss Login Window  |
| - Network / Server Err  |             | 4. Reveal FloatingView   |
+-------------------------+             +--------------------------+
```

---

## Building the Dynamic Library (`.dylib`)

On macOS with Xcode installed:

```bash
# Build the arm64 dynamic library
make

# Clean build artifacts
make clean
```

Or compile manually using `clang`:

```bash
xcrun -sdk iphoneos clang -arch arm64 -miphoneos-version-min=14.0 \
  -fobjc-arc -O2 -I./include \
  -dynamiclib -install_name @rpath/DefineAura.dylib \
  -framework UIKit -framework Foundation -framework Security -framework CoreGraphics \
  src/*.m -o DefineAura.dylib
```

---

## Injecting into an Application / IPA

1. **Using `optool` or `insert_dylib`:**
   ```bash
   optool install -c load -p "@executable_path/Frameworks/DefineAura.dylib" -t Payload/TargetApp.app/TargetApp
   ```
2. Copy `DefineAura.dylib` into `Payload/TargetApp.app/Frameworks/`.
3. Sign and package the `.ipa` using your developer certificate or distribution profile (e.g., via `ldid`, `codesign`, TrollStore, or Sideloadly).
