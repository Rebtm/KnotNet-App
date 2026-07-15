# Project Rules: KnotNet Web & iOS Application

This rule file provides critical constraints and setup guides for developers and AI agents working on the KnotNet FastAPI Backend and SwiftUI iOS Client in this workspace.

---

## 🐍 1. Python FastAPI Backend & Models

*   **Pipeline Location**: The core ML pipeline and preloaded model weights are located in the sibling folder [knotnet_1](file:///Users/tom/documents/Github/knotnet_1) (with deployment weights in `knotnet_1/knotnet_deployment/`).
*   **YOLO Block Dependency**: To execute the `YOLOv26x-pose` crossing-detection model, the python virtual environment **must** run `ultralytics>=8.3.0` (preferably latest 8.4+). Older versions (like 8.2.x) will throw `AttributeError: Can't get attribute 'C3k2'` during weight loading.
*   **Network Binding**: The FastAPI server (`backend/main.py`) must bind to `0.0.0.0` (port `8000`) instead of `127.0.0.1` to be reachable by iOS devices over the local Wi-Fi. It must automatically detect and print the host Mac's local network IP on startup.
*   **Data Types**: The backend must serialize complex pipeline outputs (like list-based `dt_notation` and `gauss_code`) to strings before returning them in the JSON payload to prevent client-side parsing failures.

---

## 📱 2. Xcode Project & iOS SwiftUI Client

*   **Xcode Project References**: In the `project.pbxproj` file, the executable target bundle (`KnotNetApp.app`) must be declared under `PBXFileReference` with `explicitFileType = wrapper.application` and linked in both `PBXNativeTarget.productReference` and the `Products` group. If missing, Xcode will compile the code ("Build Succeeded") but fail to run or launch the app.
*   **Xcode Scheme**: A valid `.xcscheme` file must exist at `KnotNetApp.xcodeproj/xcshareddata/xcschemes/KnotNetApp.xcscheme` containing the correct `BuildableReference` tags and `BuildableName = "KnotNetApp.app"` attribute to enable launching on iOS Simulators and plugged-in devices.
*   **SwiftUI API Resiliency**: All codable models representing the backend response (like `KnotResponse`, `Topology`, `PDCode`) **must** use optional types (`?` and default fallback operators `??`) for all fields. This prevents JSON parsing failures if the backend returns null or empty values for certain invariants.
*   **iOS Permissions**: The `Info.plist` file must include:
    - `NSCameraUsageDescription` (to capture live pictures of knots).
    - `NSPhotoLibraryUsageDescription` (to select pictures from the gallery).
    - `NSAppTransportSecurity` (specifically `NSAllowsArbitraryLoads = true`) to permit local unencrypted HTTP requests to the Mac backend server.
