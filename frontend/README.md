# Frontend — Portal Acadêmico Integrado AGMRM

> **Módulo da Aplicação Cliente**: `.../PI-IV-Time3/frontend/`  
> **Ecossistema**: Plataforma Educacional Integrada AGMRM (*PI-IV Time 3*)  
> **Padrões de Engenharia**: Clean Architecture Feature-First, Segurança Multi-Perfil, Inicialização Automatizada de Backend  

O módulo `frontend` abriga a aplicação cliente multiplataforma da **Plataforma Educacional Integrada AGMRM** (*PI-IV Time 3*), construída com **Flutter 3** e Dart. Ele fornece uma interface institucional abrangente, acessível e responsiva para três perfis de usuário: **Discente (*Student*)**, **Docente (*Teacher*)** e **Administrador (*Admin*)**.

---

## 🏛️ Arquitetura (Clean Architecture Feature-First)

A base de código segue estritamente os princípios da Clean Architecture Feature-First, desacoplando regras de negócio de domínio dos frameworks de apresentação de interface e das fontes de dados externas:

$$\text{Camada de Apresentação (Widgets \& Controllers)} \longleftrightarrow \text{Camada de Domínio (UseCases \& Entities)} \longleftrightarrow \text{Camada de Dados (Repositories \& DataSources)}$$

### Módulos Funcionais Principais:
1. **`auth`**: Fluxos seguros de autenticação e recuperação de credenciais:
   - Login multi-perfil (Discente, Docente, Administrador).
   - Recuperação de senha com mitigação de ataques de temporização (side-channel timing).
   - Verificação de código OTP com temporizador de contagem regressiva efêmero.
   - Redefinição de senha com indicador de avaliação de entropia de 4 fatores.
2. **`student`**: Portal do Discente com notas semestrais, diário de frequência, grade horária de aulas, calendário acadêmico e requerimentos da secretaria virtual.
3. **`teacher`**: Portal do Docente com lançamento de notas, chamada digital em aula, validação de frequência e gestão de materiais pedagógicos.
4. **`admin`**: Portal de Administração Acadêmica com gestão do ciclo de vida de identidades de usuários, cockpit de auditoria, balcão de secretaria e trava regimental de notas do CONSEPE.
5. **`video_call`**: Módulo institucional de Videochamada WebRTC P2P com:
   - Sala de espera com diagnósticos de hardware (verificações de câmera e microfone).
   - Grade de vídeo dinâmica com detecção de orador ativo baseada em histerese.
   - Fila ordenada FIFO de dúvidas (Mãos Levantadas) e chat da sessão em tempo real.
   - Compartilhamento de tela e gravação de sessão com registro de auditoria institucional.
   - Acesso regimental de abertura de sala restrito estritamente a Docente ou Administrador.
   - Entrada na sala, emissão de tíquete de uso único e sinalização WebSocket executam no servidor Java (`:8080`); mídia de áudio/vídeo permanece peer-to-peer via WebRTC.
6. **`multiperfil`**: Ponte de interoperabilidade acadêmica (*Academic Bridge*) orquestrando eventos sincronizados entre perfis de Discente, Docente e Administrador.

---

## 📂 Estrutura de Diretórios

```
.../PI-IV-Time3/frontend/
├── lib/
│   ├── core/
│   │   ├── backend/
│   │   │   └── backend_process_launcher.dart  # Inicializador transparente em segundo plano dos módulos principais
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
│   └── main.dart                             # Ponto de entrada da aplicação Flutter
├── test/                                     # Suíte abrangente de testes automatizados (396 testes)
│   ├── features/
│   │   ├── admin/
│   │   ├── auth/
│   │   ├── multiperfil/
│   │   ├── student/
│   │   ├── teacher/
│   │   └── video_call/
│   └── widget_test.dart
├── pubspec.yaml                              # Dependências da aplicação (incluindo agmrm_security)
└── README.md                                 # Manual técnico do frontend (este arquivo)
```

---

## 🚀 Executando o Projeto

Graças ao mecanismo de automação integrado, **não são necessários scripts de inicialização separados nem múltiplas janelas de terminal**:

```bash
# 1. Navegue até o diretório frontend
cd .../PI-IV-Time3/frontend

# 2. Inicie a aplicação
flutter run
```

Ao executar `flutter run`:
- O Flutter compila e inicia o cliente desktop/web.
- O servidor Java de Identidade, Usuários Administrativos e WebSocket de Videochamada em `server/` (`:8080`) é iniciado automaticamente quando necessário.
- O Núcleo Acadêmico e API de Arquivos em TypeScript em `backend/` (`:3001`) deve estar em execução (`npm run dev` ou inicializador automático do desktop).
- O pacote corporativo de segurança (`security/`) é declarado como dependência local em `pubspec.yaml`.

Para uma implantação Web não local, configure:
- `AUTH_API_BASE_URL` para o servidor Java de Identidade e Videochamada (padrão `http://127.0.0.1:8080`)
- `ACADEMIC_API_BASE_URL` (ou fallback `API_BASE_URL`) para o Núcleo Acadêmico em TypeScript (padrão `http://127.0.0.1:3001`)
- `VIDEO_CALL_WS_BASE_URL` para o endpoint WebSocket em Java (padrão `ws://127.0.0.1:8080`, utilize `wss://` em produção)

---

## 🧪 Qualidade de Código e Testes

A base de código mantém padrões rigorosos de engenharia corporativa:

```bash
# Análise estática de código (0 problemas / 0 avisos)
flutter analyze

# Execução da suíte abrangente de testes automatizados (396 testes aprovados)
flutter test
```
