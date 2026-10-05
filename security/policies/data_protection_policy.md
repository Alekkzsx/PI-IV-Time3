# Política de Proteção de Dados e Privacidade (Conformidade LGPD)

## 1. Fundamentação Legal e Finalidade

A presente **Política de Proteção de Dados Pessoais** estabelece as diretrizes para a coleta, tratamento, armazenamento, compartilhamento e eliminação de dados pessoais no âmbito do **Portal Acadêmico AGMRM** (`PI-IV-Time3`), em estrita conformidade com a **Lei Geral de Proteção de Dados Pessoais (LGPD - Lei nº 13.709/2018)**, o **Marco Civil da Internet (Lei nº 12.965/2014)** e as normas regulatórias do **Ministério da Educação (MEC)**.

Esta política abrange todos os dados tratados através da aplicação frontend Flutter Web, dos serviços de backend Java nativos e do banco de dados MongoDB.

---

## 2. Categorias de Dados Tratados no Portal Acadêmico

O sistema processa as seguintes classes de informações pessoais e acadêmicas:

| Categoria | Tipos de Dados Específicos | Finalidade do Tratamento |
|---|---|---|
| **Identificadores Pessoais** | Nome completo, R.A. (Registro Acadêmico), Matrícula institucional, E-mail acadêmico (`aluno@agmrm.edu.br`) | Autenticação, controle de acesso e identificação inequívoca do estudante. |
| **Registros Acadêmicos** | Notas de provas (`p1`, `p2`), trabalhos escolares (`trabalho`), pesos de avaliação, médias finais calculadas e status no boletim (`APROVADO`, `EM_RECUPERACAO`, `REPROVADO_POR_NOTA`) | Cumprimento das exigências pedagógicas e emissão de histórico escolar oficial. |
| **Registros de Frequência** | Minutos de aula assistidos (`minutosAssistidos`), duração total da sessão (`duracaoTotal`), percentual de presença e justificativas manuais de faltas | Comprovação de cumprimento da carga horária mínima regulamentar exigida pela LDB (Lei 9.394/1996). |
| **Metadados de Segurança e Conexão** | Endereço IP de origem, porta de conexão, User-Agent do navegador, data/hora das requisições e tokens temporários de sessão | Segurança da informação, prevenção a fraudes em avaliações e cumprimento do Art. 15 do Marco Civil da Internet. |

---

## 3. Bases Legais para o Tratamento de Dados (Art. 7º da LGPD)

O tratamento de dados no Portal Acadêmico fundamenta-se estritamente nas seguintes hipóteses legais autorizadoras:

1. **Cumprimento de Obrigação Legal ou Regulatória (Art. 7º, II)**:
   - Registro de notas e presença em cumprimento às diretrizes da LDB e normas do Conselho Nacional de Educação (CNE/MEC).
   - Guarda de registros de acesso à aplicação pelo prazo de 6 meses (Art. 15 da Lei 12.965/2014).
2. **Execução de Contrato de Prestação de Serviços Educacionais (Art. 7º, V)**:
   - Viabilização do acesso ao ambiente virtual de aprendizagem, submissão de tarefas avaliativas e emissão de boletins parciais e finais.
3. **Legítimo Interesse da Instituição e Segurança do Titular (Art. 7º, IX)**:
   - Monitoramento de acessos para prevenção de acessos indevidos, ataques de força bruta e proteção da integridade da base de notas.

---

## 4. Direitos dos Titulares de Dados (Art. 18 da LGPD)

O Portal Acadêmico AGMRM assegura aos estudantes, docentes e colaboradores o pleno exercício de seus direitos:

| Direito | Mecanismo de Atendimento no Portal |
|---|---|
| **Confirmação e Acesso** | O aluno pode consultar seus dados cadastrais, notas e frequências em tempo real via tela de Boletim e Diário de Classe. |
| **Correção de Dados Incompletos ou Inexatos** | Solicitação formal de retificação de notas ou presença perante a secretaria acadêmica ou professor responsável. |
| **Anonimização e Bloqueio** | Aplicação de mascaramento de dados em ambientes de homologação e testes de desenvolvimento (`testeServidor.txt` / staging). |
| **Portabilidade de Dados** | Exportação de histórico de notas e frequências em formato estruturado e legível por máquina (JSON / CSV). |
| **Informação sobre Compartilhamento** | Esclarecimento de que os dados acadêmicos são compartilhados exclusivamente com os órgãos reguladores oficiais (MEC/INEP). |

---

## 5. Medidas Técnicas e Administrativas de Segurança da Informação

Para proteger os dados pessoais contra acessos não autorizados, destruição acidental, vazamento ou adulteração:

### 5.1 Criptografia em Trânsito e em Repouso
- Todo o tráfego entre a aplicação Flutter Web e a API Java deve utilizar **TLS 1.3** com cifras criptográficas modernas.
- As credenciais de acesso e senhas são salvas no banco MongoDB utilizando derivação com **Argon2id** ou **BCrypt (cost 12)**.
- Tokens de recuperação de senha têm validade estrita de **5 minutos** e são armazenados exclusivamente sob hash criptográfico SHA-256.

### 5.2 Controle de Acesso Restrito e Segregação de Perfis (RBAC)
- Alunos têm acesso estrito aos seus próprios registros acadêmicos. O acesso aos dados de terceiros é bloqueado por design (isolamento por `student_id`).
- Professores têm acesso restrito aos alunos pertencentes às suas turmas ativas.
- Acesso à infraestrutura de banco de dados é restrito a administradores cadastrados com autenticação de dois fatores (MFA).

### 5.3 Proibição de Exposição em Ambientes de Teste
- Arquivos de teste e scripts automatizados (como `testeServidor.txt`) devem utilizar estritamente dados sintéticos ou fictícios, sendo vedada a clonagem de bases reais de alunos para estações de trabalho de desenvolvedores.

---

## 6. Ciclo de Vida e Tabela de Retenção de Dados

| Categoria do Dado | Período de Retenção | Destinação Final |
|---|---|---|
| **Boletins e Registros de Matrícula** | Permanente (ou conforme tabela de temporalidade documental do MEC - Portaria 315/2018) | Arquivo permanente digitalizado com assinatura digital ICP-Brasil. |
| **Logs de Sessão e Acesso (IP/Horário)** | 6 meses corridos (Marco Civil da Internet) | Descarte seguro e expurgo automatizado. |
| **Tokens de Redefinição de Senha** | 5 minutos (Regra Institucional) | Invalidação imediata e expurgo de memória/banco. |
| **Tentativas de Conexão Mal-sucedidas** | 30 dias para análise de segurança | Expurgo automático após rotatividade de logs. |

---

## 7. Procedimento de Notificação em Caso de Incidentes de Segurança

Na eventualidade de um incidente de segurança que acarrete risco ou dano relevante aos titulares de dados (ex: vazamento de boletins ou adulteração de notas):
1. **Comunicação Imediata ao Encarregado pelo Tratamento de Dados (DPO)** da instituição em até 2 horas após a identificação.
2. **Mitigação Técnica**: Isolamento imediato do serviço comprometido e revogação das chaves de acesso afetadas.
3. **Notificação à Autoridade Nacional de Proteção de Dados (ANPD)** e aos titulares afetados em prazo razoável, contendo a descrição da natureza dos dados comprometidos e as medidas de segurança adotadas para mitigar os efeitos.
