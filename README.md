# Integrated Educational Platform (AGMRM)

Projeto desenvolvido para a disciplina de **Projeto Integrador 4** do curso de Engenharia de Software da **PUC-Campinas** (2026).

---

## 🏛️ Sobre o Projeto

A **Plataforma Educacional Integrada (AGMRM)** é um ecossistema acadêmico unificado e multiplataforma desenvolvido pela Equipe 3. 

A plataforma soluciona a fragmentação de ferramentas educacionais integrando controle de frequência regimental, diário de classe digital, cálculo de notas e médias ponderadas, submissão de tarefas com penalidade por atraso, salas virtuais de videochamada institucional com sinalização WebRTC, e uma sólida arquitetura de defesa cibernética em profundidade.

### Principais Funcionalidades

- **Portais Específicos por Perfil de Usuário**:
  - **Portal do Aluno**: Boletim com médias ponderadas, faltas, quadro de horários, comunicados e secretaria virtual.
  - **Portal do Docente**: Lançamento de notas, diário de classe com chamada digital, homologação de presença e abertura de salas virtuais.
  - **Portal do Administrador**: Gestão de identidades, cockpits de auditoria, secretaria acadêmica e lacre regimental de pautas CONSEPE.
- **Módulo de Videochamada Institucional (`video_call`)**:
  - Conferência P2P WebRTC integrada ao servidor nativo Java (`server/`).
  - Detecção de orador ativo com histerese (*Active Speaker*), fila FIFO de dúvidas (mãos levantadas), chat em tempo real e verificação de presença por minutos conectados.
  - Restrição regimental: apenas docentes e administradores podem abrir salas de aula virtuais.
- **Servidor HTTP Nativo em Java SE (`server/`)**:
  - Servidor construído do zero sobre sockets padrão Java SE (zero dependência de frameworks externos).
  - 13 endpoints ativos na porta `8080` cobrindo módulos acadêmicos e sinalização WebRTC.
- **Segurança Corporativa e Defesa em Profundidade (`security/`)**:
  - Bloqueio por força bruta (5 tentativas falhas $\rightarrow$ 30s de lockout).
  - Mitigação de ataques de temporização (*timing attacks*).
  - Respostas opacas anti-enumeração e sanitização pré-flight contra XSS e injeção SQL.

---

## 👥 Equipe do Projeto Integrador IV (Time 3)

| Nome Completo | RA |
|---|---|
| Alex Gabriel Soares Sousa | 24802449 |
| Guilherme Henrique Moreira | 25006702 |
| Marcelo Zarpelon | 25015323 |
| Murillo Caravita | 25014012 |
| Rafael Henrique Inácio | 25009719 |

---

## 📂 Estrutura do Repositório

```
.../PI-IV-Time3/
├── .github/                  # CI/CD workflows, CODEOWNERS, GOVERNANCE.md e configurações de IDE (.vscode)
├── frontend/                 # Aplicação multiplataforma Flutter (Feature-First Clean Architecture, 396 testes)
│   ├── lib/
│   │   ├── core/             # Design tokens, backend launcher automático, rotas e tema
│   │   ├── features/         # auth, student, teacher, admin, video_call, multiperfil
│   │   └── main.dart         # Ponto de entrada com disparo transparente das pastas mães
│   └── test/                 # Suíte completa com 396 testes automatizados
├── server/                   # Servidor HTTP nativo autônomo em Java SE (zero frameworks externos)
│   ├── src/
│   │   ├── main/             # Main.java — Registro central dos 13 endpoints na porta 8080
│   │   ├── core/             # Sockets nativos, manipuladores HTTP e CORS
│   │   ├── academic/         # Boletim, Presença, Tarefas e Tipos
│   │   └── videocall/        # Salas, Sinalização WebRTC, Chat, Mãos Levantadas e Presença
│   └── tests/                # 16 comandos cURL documentados (testeServidor.txt)
├── security/                 # Arquitetura corporativa de Defesa em Profundidade (37 testes)
│   ├── lib/                  # Pacote Dart/Flutter (auth, policies, validators, widgets)
│   ├── test/                 # Testes unitários e de integração de segurança
│   └── server/               # Guardas de segurança do servidor em Java SE (src e test)
├── backend/                  # Orquestração institucional e camada de persistência
│   ├── backend-config.json   # Configuração dos módulos para integração transparente ao 'flutter run'
│   └── target/classes/       # Entidades, modelos e repositórios acadêmicos
└── .env-example              # Modelo mestre unificado de variáveis de ambiente de todo o projeto
```

---

## 🚀 Executando o Projeto Localmente

### Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x ou superior)
- [Java Development Kit (JDK 8 ou superior / JDK 17/21 recomendado)](https://www.oracle.com/java/technologies/downloads/)
- Git

---

### Inicialização Transparente (`cd frontend` & `flutter run`)

**Não é necessário rodar scripts avulsos ou abrir múltiplos terminais.** Ao executar `flutter run`, o Flutter e o sistema operacional coordenam a inicialização de todos os serviços automaticamente:

```bash
# 1. Clone o repositório
git clone https://github.com/Alekkzsx/PI-IV-Time3.git
cd .../PI-IV-Time3

# 2. Acesse a pasta do frontend e execute
cd frontend
flutter run
```

O comando irá:
1. Compilar e abrir a aplicação Flutter (desktop Windows ou navegador Web).
2. Inicializar o servidor nativo Java (`server/`) e o backend na porta **8080** em segundo plano.
3. Resolver os contratos corporativos da biblioteca de segurança (`security/`).

---

## 🧪 Qualidade, Análise Estática e Testes

O projeto conta com mais de 430 testes automatizados distribuídos entre o cliente Flutter, as rotas do servidor e a biblioteca de segurança:

```bash
# 1. Testes e análise do Frontend (396 testes, 0 issues)
cd .../PI-IV-Time3/frontend
flutter analyze
flutter test

# 2. Testes e análise do módulo Security (37 testes, 0 issues)
cd .../PI-IV-Time3/security
flutter analyze
flutter test
```

Para verificar o servidor nativo Java via cURL, consulte a bateria com 16 comandos em `.../PI-IV-Time3/server/tests/testeServidor.txt`.

---

*Projeto Integrador 4 — Engenharia de Software — PUC-Campinas — 2026*
