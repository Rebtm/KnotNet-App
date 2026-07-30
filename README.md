# KnotNet App

End-to-End Mobile Application & FastAPI Backend for Neural Knot Recognition and Topological Analysis.

---

## Overview

**KnotNet App** combines an advanced **FastAPI Backend** (running the KnotNet V5 Pipeline with YOLOv8 & SymPy topological analysis) with a modern **iOS Application** built natively in **SwiftUI**.

The app allows users to photograph knots, detect crossing keypoints, trace strand traversals, compute invariants (Jones Polynomial, Planar Diagram Code, Gauss Code, Writhe), and explore high-resolution visual output.

---

## Features

- **Native SwiftUI Frontend**:
    - **Swipeable Visualizer Carousel**: Swipe between **Detections (Groß)**, **Traversal (Groß)**, and **Original Photo**.
    - **Tap-to-Zoom Fullscreen Modal**: Inspect high-resolution model output image in full screen.
    - **Knot Classification**: Automatic identification of Trefoil ($3_1$), Figure-Eight ($4_1$), Unknot ($0_1$), and complex knots.
    - **Topological Invariants Card**: Renders **Jones Polynomials** $V(A)$ (with full Laurent polynomial support for negative exponents), PD-Codes, Gauss-Codes, and DT-Notations.
    - **Performance Profiler**: Real-time breakdown of inference latency per stage (preprocessing, YOLO detection, graph traversal, topology).
    - **Custom Neon App Icon**: Pre-configured asset catalog for iOS 16+.

- **FastAPI Backend**:
    - Standalone high-res visualization rendering (Detection, Traversal sequence arrows).
    - Automatic local Wi-Fi IP detection for seamless connection to real iOS devices.
    - CORS enabled for local network development.

---

## Repository Structure

```
KnotNet-App/
├── backend/
│   ├── main.py              # FastAPI server & inference endpoint (/predict)
│   ├── requirements.txt     # Python dependencies
│   └── static/              # Storage for uploaded & result visualization images
└── ios/
    ├── KnotNetApp.xcodeproj  # Xcode project configuration
    ├── generate_xcodeproj.py# Script to generate project configuration
    └── Sources/
        ├── KnotNetApp.swift # App entry point
        ├── ContentView.swift# Main camera & upload view
        ├── ResultView.swift # Detailed analysis results & visualizer carousel
        ├── CameraView.swift # Native camera picker wrapper
        ├── NetworkClient.swift # URLSession HTTP client for FastAPI backend
        ├── KnotModels.swift # Codable data models
        ├── Info.plist       # Permissions & app metadata
        └── Assets.xcassets  # App icon & image assets
```

---

## Getting Started

### 1. Start the Backend Server

Navigieren Sie in das `backend`-Verzeichnis, aktivieren Sie das Virtual Environment und starten Sie den Server:

```bash
cd backend

# Virtual Environment aktivieren
source .venv/bin/activate

# Backend-Server starten
python main.py
```

Das Backend startet unter `http://0.0.0.0:8000` (sowie über Ihre lokale WLAN-IP `http://192.168.x.x:8000`).

---

### 2. iOS App ausführen

#### Option A: Über Xcode (GUI)

1. Öffnen Sie `ios/KnotNetApp.xcodeproj` in Xcode.
2. Wählen Sie Ihr **iPhone** oder einen **Simulator** als Zielgerät oben aus.
3. Wählen Sie unter _Signing & Capabilities_ Ihr Personal Team aus.
4. Drücken Sie **`Cmd + R`** (bzw. den _Play_-Button).

#### Option B: Über das Terminal (auf echtem iPhone)

```bash
cd ios
xcodebuild -project KnotNetApp.xcodeproj -scheme KnotNetApp -sdk iphoneos build
```

---

## Hinweis für beste Ergebnisse

Damit die KnotNet Pipeline die Traversierungs-Sequenz ($A \to Z$) berechnen kann, stellen Sie bitte sicher, dass **beide Seilenden** auf dem Foto vollständig sichtbar sind!
