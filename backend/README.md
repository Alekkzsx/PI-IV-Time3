# Backend — Enterprise Academic Services, Persistence & Orchestration (AGMRM)

> **Módulo**: `.../PI-IV-Time3/backend/`  
> **Ecossistema**: Plataforma Educacional Integrada AGMRM (*PI-IV Time 3*)  

---

## 🏛️ Propósito Arquitetural e Orquestração

O módulo `backend` define a camada corporativa de persistência, regras de negócio distribuídas, gestão de identidade e orquestração de serviços para a **Plataforma Educacional Integrada AGMRM**.

Enquanto o servidor nativo em `.../PI-IV-Time3/server/` provê execução de alta performance e cálculo síncrono em sockets HTTP (rotas acadêmicas e sinalização WebRTC de videochamada), o módulo `backend` orquestra:

1. **Configuração Unificada de Serviços (`backend-config.json`)**: Especificação declarativa de portas, endpoints, health checks e contratos de comunicação.
2. **Camada de Persistência e Entidades (`target/classes/`)**: Modelos e repositórios acadêmicos (`models/Usuario`, `admin/repositories/UsuarioRepository`, `database/MongoDBConnection`).
3. **Orquestração Automática no `flutter run`**: Interligação para que a execução do Flutter no frontend levante todos os módulos de backend de forma transparente.

---

## 📂 Estrutura de Arquivos

```
.../PI-IV-Time3/backend/
├── backend-config.json           # Configuração de orquestração institucional
├── target/classes/               # Classes compiladas de modelos, repositórios e banco
│   ├── academico/                # Controllers acadêmicos
│   ├── admin/                    # Controllers e UsuarioRepository
│   ├── database/                 # Conexão MongoDB (MongoDBConnection)
│   ├── models/                   # Modelo Usuario
│   ├── server/                   # ServidorHttpNativo e utilitários
│   └── utils/                    # JsonSimples e parsers
├── .gitkeep                      # Preservação de controle de versão
└── README.md                     # Documentação técnica do backend (este arquivo)
```

---

## ⚙️ Configuração Institucional (`backend-config.json`)

O arquivo `.../PI-IV-Time3/backend/backend-config.json` parametriza a inicialização das pastas mães do ecossistema:

```json
{
  "_description": "Configuracao institucional do ecossistema de backend AGMRM para integracao transparente ao 'flutter run'",
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
        "academic_task_grading"
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
    "description": "Ao executar 'cd frontend' e 'flutter run', os servicos do server e backend iniciam automaticamente em background."
  }
}
```

---

## 🔄 Inicialização Integrada ao `flutter run`

Não há necessidade de inicializadores manuais ou scripts avulsos:
- Ao entrar em `.../PI-IV-Time3/frontend` e executar `flutter run`, o Flutter lê as configurações de orquestração do backend, assegura a integridade das pastas mães e levanta os serviços em background na porta 8080.
