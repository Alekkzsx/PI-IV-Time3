# Backend — Enterprise Academic Services, Persistence & Orchestration (AGMRM)

> **Module**: `.../PI-IV-Time3/backend/`  
> **Ecosystem**: Integrated Educational Platform AGMRM (*PI-IV Team 3*)  
> **Engineering Standards**: Enterprise Persistence, Transparent Orchestration, Clean Architecture  

---

## 🏛️ Architectural Purpose & Orchestration

The `backend` module defines the enterprise persistence layer, distributed business rules, identity management, and service orchestration for the **Integrated Educational Platform AGMRM**.

While the native server in `.../PI-IV-Time3/server/` provides high-performance, zero-dependency socket communication (academic calculations, real email OTP dispatch, and WebRTC video call signaling), the `backend` module orchestrates:

1. **Unified Service Configuration (`backend-config.json`)**: Declarative specification of ports, endpoints, health checks, and communication contracts.
2. **Persistence Layer & Entities (`target/classes/`)**: Academic models and repositories (`models/Usuario`, `admin/repositories/UsuarioRepository`, `database/MongoDBConnection`).
3. **Automated `flutter run` Orchestration**: Seamless integration ensuring that running Flutter in the frontend transparently initializes all backend parent modules.

---

## 📂 File Structure

```
.../PI-IV-Time3/backend/
├── backend-config.json           # Declarative orchestration configuration
├── target/classes/               # Compiled bytecode of models, repositories, and DB connectors
│   ├── academico/                # Academic controllers
│   ├── admin/                    # Controllers and UsuarioRepository
│   ├── database/                 # MongoDB database connector (MongoDBConnection)
│   ├── models/                   # Core domain models (Usuario)
│   ├── server/                   # ServidorHttpNativo and utility classes
│   └── utils/                    # JsonSimples and payload parsers
├── .gitkeep                      # Version control anchor
└── README.md                     # Backend technical manual (this file)
```

---

## ⚙️ Institutional Configuration (`backend-config.json`)

The file `.../PI-IV-Time3/backend/backend-config.json` parameterizes the automated startup of all parent modules:

```json
{
  "_description": "Institutional configuration of the AGMRM backend ecosystem for transparent integration with 'flutter run'",
  "environment": {
    "profile": "development",
    "orchestrator": "frontend_integrated_launcher"
  },
  "modules": {
    "server": {
      "path": "../server",
      "entrypoint": "main.Main",
      "port": 8080,
      "protocol": "HTTP/1.1",
      "auto_start": true,
      "healthcheck": "http://127.0.0.1:8080/api/videocall/rooms",
      "features": [
        "videocall_webrtc_signaling",
        "academic_boletim_calculation",
        "academic_attendance_tracking",
        "academic_task_grading",
        "auth_smtp_recovery_otp"
      ]
    },
    "security": {
      "path": "../security",
      "package": "agmrm_security",
      "auto_bind": true,
      "features": [
        "generic_feedback_policy",
        "rate_limiting_lockout",
        "input_sanitizer",
        "timing_attack_mitigation"
      ]
    },
    "backend_persistence": {
      "target_classes": "target/classes",
      "database": "mongodb_integrated",
      "status": "ready"
    }
  },
  "flutter_run_hook": {
    "enabled": true,
    "strategy": "dual_trigger_cmake_and_dart_vm",
    "description": "When executing 'cd frontend' and 'flutter run', server and backend services initialize automatically in the background."
  }
}
```

---

## 🔄 Integrated Initialization with `flutter run`

No manual initializers or separate scripts are necessary:
- Navigating to `.../PI-IV-Time3/frontend` and executing `flutter run` reads the backend orchestration specifications, verifies the integrity of all parent modules, and starts the native services in the background on port 8080.
