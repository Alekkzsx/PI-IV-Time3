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
- Parent module services (`server/` with all 15 endpoints including real SMTP OTP dispatch and `backend/` persistence) are **automatically initialized in the background**.
- The enterprise security package (`security/`) is resolved and linked directly via `pubspec.yaml`.

---

## 🧪 Code Quality & Testing

The codebase maintains strict corporate engineering standards:

```bash
# Static code analysis (0 issues / 0 warnings)
flutter analyze

# Comprehensive automated test suite execution (396 tests passed)
flutter test
```
