# Frontend — AGMRM Integrated Academic Portal

> **Client Application Module**: `.../PI-IV-Time3/frontend/`  
> **Ecosystem**: Integrated Educational Platform AGMRM (*PI-IV Team 3*)  
> **Engineering Standards**: Feature-First Clean Architecture, Multi-Role Security, Automated Backend Startup  

The `frontend` module houses the multi-platform client application of the **Integrated Educational Platform AGMRM** (*PI-IV Team 3*), built with **Flutter 3** and Dart. It provides a comprehensive, accessible, and responsive institutional interface for three user roles: **Discente (*Student*)**, **Docente (*Teacher*)**, and **Administrador (*Admin*)**.

---

## 🏛️ Architecture (Feature-First Clean Architecture)

The codebase strictly adheres to Feature-First Clean Architecture principles, decoupling domain business rules from UI presentation frameworks and external data sources:

$$\text{Presentation Layer (Widgets \& Controllers)} \longleftrightarrow \text{Domain Layer (UseCases \& Entities)} \longleftrightarrow \text{Data Layer (Repositories \& DataSources)}$$

### Core Functional Modules:
1. **`auth`**: Secure authentication and credential recovery workflows:
   - Multi-role login (Student, Teacher, Admin).
   - Password recovery with side-channel timing attack mitigation.
   - OTP code verification with ephemeral countdown timer.
   - Password reset with a 4-factor entropy evaluation indicator.
2. **`student`**: Student Portal with semester grades, attendance journal, class timetable, academic calendar, and virtual office requirements.
3. **`teacher`**: Teacher Portal with grade submission, digital class roll call, attendance validation, and pedagogical material management.
4. **`admin`**: Academic Administration Portal with user identity lifecycle management, audit cockpit, registry desk, and regimental CONSEPE grade lock.
5. **`video_call`**: Institutional P2P WebRTC Video Call module featuring:
   - Waiting lobby with hardware diagnostics (camera and microphone checks).
   - Dynamic video grid with hysteresis-based active speaker detection.
   - Ordered FIFO doubt queue (Raised Hands) and real-time session chat.
   - Screen sharing and session recording with institutional audit logging.
   - Regimental room opening access restricted strictly to Teacher or Admin.
   - Room entry, single-use ticket issuance, and WebSocket signaling run on the Java server (`:8080`); audio/video media remain peer-to-peer via WebRTC.
6. **`multiperfil`**: Academic interoperability bridge (*Academic Bridge*) orchestrating synchronized cross-role events between Student, Teacher, and Admin.

---

## 📂 Directory Structure

```
.../PI-IV-Time3/frontend/
├── lib/
│   ├── core/
│   │   ├── backend/
│   │   │   └── backend_process_launcher.dart  # Transparent parent modules background launcher
│   │   ├── errors/
│   │   ├── router/
│   │   ├── theme/
│   │   └── utils/
│   ├── features/
│   │   ├── admin/
│   │   ├── auth/
│   │   ├── multiperfil/
│   │   ├── student/
│   │   ├── teacher/
│   │   └── video_call/
│   └── main.dart                             # Flutter application entry point
├── test/                                     # Comprehensive automated test suite (396 tests)
│   ├── features/
│   │   ├── admin/
│   │   ├── auth/
│   │   ├── multiperfil/
│   │   ├── student/
│   │   ├── teacher/
│   │   └── video_call/
│   └── widget_test.dart
├── pubspec.yaml                              # Application dependencies (including agmrm_security)
└── README.md                                 # Frontend technical manual (this file)
```

---

## 🚀 Running the Project

Thanks to the integrated automation mechanism, **no separate initialization scripts or multiple terminal windows are required**:

```bash
# 1. Navigate to the frontend directory
cd .../PI-IV-Time3/frontend

# 2. Launch the application
flutter run
```

When executing `flutter run`:
- Flutter compiles and launches the desktop/web client.
- The Java Identity, Admin Users & Video-Call WebSocket server in `server/` (`:8080`) is started automatically when needed.
- The TypeScript Academic Core & File API in `backend/` (`:3001`) must be running (`npm run dev` or desktop auto-launcher).
- The enterprise security package (`security/`) is declared as a local dependency in `pubspec.yaml`.

For a non-local Web deployment, configure:
- `AUTH_API_BASE_URL` for the Java Identity & Video-Call server (default `http://127.0.0.1:8080`)
- `ACADEMIC_API_BASE_URL` (or fallback `API_BASE_URL`) for the TypeScript Academic Core (default `http://127.0.0.1:3001`)
- `VIDEO_CALL_WS_BASE_URL` for the Java WebSocket endpoint (default `ws://127.0.0.1:8080`, use `wss://` in production)

---

## 🧪 Code Quality & Testing

The codebase maintains strict corporate engineering standards:

```bash
# Static code analysis (0 issues / 0 warnings)
flutter analyze

# Comprehensive automated test suite execution (396 tests passed)
flutter test
```
