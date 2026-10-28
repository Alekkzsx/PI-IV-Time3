# Server — Zero-Dependency Native Java HTTP Server (AGMRM)

O módulo `server` contém o servidor HTTP nativo, autônomo e de alta performance desenvolvido para a **Plataforma Educacional Integrada AGMRM** (*PI-IV Time 3*). 

Opera 100% sobre a biblioteca padrão do **Java SE** (compatível com Java 8 a 21+) sem dependência de frameworks externos ou containers pesados de aplicação (zero Spring, Quarkus, Maven ou Tomcat).

---

## 🏛️ Arquitetura e Organização Modular

O servidor está estruturado em pacotes coesos com separação estrita de responsabilidades:

```
.../PI-IV-Time3/server/
├── bin/                          # Bytecode compilado (.class)
├── src/                          # Código-fonte Java modular
│   ├── main/
│   │   └── Main.java             # Ponto de entrada central e orquestrador na porta 8080
│   ├── core/                     # Abstração de Sockets HTTP nativos, Request/Response e CORS
│   │   ├── HttpUtils.java
│   │   ├── ManipuladorHttp.java
│   │   ├── RequisicaoHttp.java
│   │   ├── RespostaHttp.java
│   │   └── ServidorHttpNativo.java
│   ├── academic/                 # Handlers acadêmicos (Frequência, Boletim, Tarefas e Tipos)
│   │   ├── BoletimHandler.java
│   │   ├── PresencaHandler.java
│   │   ├── TarefasHandler.java
│   │   └── TesteTiposHandler.java
│   ├── auth/                     # Módulo de Autenticação e Disparo Real de E-mails via SMTP
│   │   ├── AuthRecoveryHandler.java
│   │   └── EmailService.java
│   └── videocall/                # Módulo de Videochamada, Sinalização WebRTC e Frequência
│       ├── VideoCallAttendanceHandler.java
│       ├── VideoCallInteractionHandler.java
│       ├── VideoCallRoomHandler.java
│       ├── VideoCallService.java
│       └── VideoCallSignalingHandler.java
├── tests/
│   └── testeServidor.txt         # Bateria com comandos cURL documentados
├── README.md                     # Documentação técnica do servidor
└── run-server.bat                # Script utilitário opcional legado
```

---

## 🧩 Responsabilidades por Pacote

- **`main` (`.../PI-IV-Time3/server/src/main/Main.java`)**:
  - Ponto de entrada unificado da aplicação Java.
  - Orquestra e registra todas as 15 rotas nos módulos acadêmico, videochamada e autenticação na porta 8080.
- **`core` (`.../PI-IV-Time3/server/src/core/`)**:
  - Abstrações nativas de baixo nível sobre `ServerSocket` e sockets TCP.
  - Gerenciamento de ciclo de vida HTTP (Request, Response, Headers, CORS e body parser).
- **`academic` (`.../PI-IV-Time3/server/src/academic/`)**:
  - Regras de negócio de notas semestrais e cálculo de média ponderada regimental.
  - Apuração de faltas, horas-aula e cálculo de frequência com suporte a abono docente.
  - Lógica de dedução automática por entrega de tarefas em atraso.
- **`auth` (`.../PI-IV-Time3/server/src/auth/`)**:
  - `EmailService.java`: Cliente SMTP nativo sobre SSL Socket (porta 465) em Java puro (RFC 5321). Disparo real de e-mails com código de confirmação OTP de 6 dígitos em template HTML responsivo.
  - `AuthRecoveryHandler.java`: Endpoints de envio e validação com TTL de 300 segundos (5 minutos) e bloqueio contra força bruta (máximo de 3 tentativas).
- **`videocall` (`.../PI-IV-Time3/server/src/videocall/`)**:
  - Gestão do ciclo de vida de salas de aula virtuais (abertura regimental restrita a Docente ou Admin).
  - Hub de sinalização WebRTC (troca de SDP Offer/Answer e ICE Candidates).
  - Fila FIFO ordenada de dúvidas ("Mãos Levantadas") e chat em tempo real.
  - Apuração automática de presença dos discentes com base no tempo de conexão na videochamada.

---

## 🚀 Inicialização Transparente (`cd frontend` & `flutter run`)

O servidor **não requer inicialização manual** no fluxo de trabalho padrão de desenvolvimento:

1. Ao abrir o terminal na pasta do frontend e executar:
   ```bash
   cd frontend
   flutter run
   ```
2. O Flutter aciona a automação pré-execução via CMake e `BackendProcessLauncher`:
   - Verifica se a porta `8080` já está ativa.
   - Caso esteja inativa, compila os arquivos `.java` para `server/bin/` utilizando `javac --release 8`.
   - Inicializa `java -cp bin main.Main` em background (*detached*), liberando a aplicação Flutter para se comunicar com todos os endpoints instantaneamente.

*(Opcional / Manual)*: Caso deseje executar o servidor isoladamente no terminal:
```bash
cd .../PI-IV-Time3/server
javac --release 8 -encoding UTF-8 -d bin src/core/*.java src/academic/*.java src/auth/*.java src/videocall/*.java src/main/*.java
java -cp bin main.Main
```

---

## 📡 Catálogo Completo de Endpoints Registrados (15 Rotas)

O servidor responde em `http://localhost:8080` com as seguintes rotas ativas:

| Método | Endpoint | Módulo | Descrição / Payload |
|---|---|---|---|
| `GET`/`POST` | `/api/teste-tipos` | Acadêmico | Diagnóstico e eco de tipos primitivos (texto, numérico, booleano) |
| `POST` | `/api/presenca` | Acadêmico | Cálculo de frequência percentual e abono de faltas |
| `POST` | `/api/tarefas/calcular-nota` | Acadêmico | Cálculo de nota com dedução regimental por entrega em atraso |
| `POST` | `/api/notas/boletim` | Acadêmico | Média ponderada semestral e verificação de aprovação |
| `GET` | `/api/videocall/rooms` | Videochamada | Listagem de salas de aula virtuais ativas e status de saúde |
| `POST` | `/api/videocall/open` | Videochamada | Abertura de sala institucional (**apenas Docente ou Admin**) |
| `POST` | `/api/videocall/close` | Videochamada | Encerramento regimental de sala (**apenas Docente ou Admin**) |
| `POST` | `/api/videocall/join` | Videochamada | Entrada de discente/docente com registro de telemetria |
| `POST` | `/api/videocall/leave` | Videochamada | Saída de participante e gravação de tempo de permanência |
| `POST` | `/api/videocall/signal` | Videochamada | Sinalização WebRTC P2P (troca de SDP Offer/Answer e ICE candidates) |
| `POST` | `/api/videocall/hand-raise` | Videochamada | Gestão de fila FIFO de dúvidas e mãos levantadas |
| `POST` | `/api/videocall/chat` | Videochamada | Mensageria instantânea com timestamp da sala virtual |
| `POST` | `/api/videocall/attendance`| Videochamada | Homologação de presença baseada nos minutos conectados na chamada |
| `POST` | `/api/auth/send-recovery-otp` | Autenticação & E-mail | Geração de OTP de 6 dígitos e disparo real via SMTP SSL/TLS (5 min TTL) |
| `POST` | `/api/auth/verify-recovery-otp` | Autenticação & E-mail | Validação de código OTP com limitação estrita de até 3 tentativas |

---

## 🧪 Testes e Validação de Endpoints

Para validar todos os endpoints via terminal, consulte o arquivo `.../PI-IV-Time3/server/tests/testeServidor.txt`, que contém 16 comandos `curl` documentados cobrindo fluxos de sucesso e restrições regimentais.
