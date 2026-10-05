# Política de Segurança e Divulgação de Vulnerabilidades (SECURITY.md)

## 1. Compromisso Institucional de Segurança

A equipe de desenvolvimento do **Portal Acadêmico AGMRM** (`PI-IV-Time3`) assume o compromisso fundamental de assegurar a integridade, confidencialidade e disponibilidade de todas as informações acadêmicas, cadastrais e institucionais confiadas à nossa plataforma.

Tratamos relatórios de segurança com a mais alta prioridade institucional e encorajamos a comunidade e pesquisadores de segurança independentes a praticarem a **divulgação responsável (*Responsible Disclosure*)**.

---

## 2. Versões Suportadas

Apenas as versões ativas do repositório recebem atualizações contínuas de segurança e correções emergenciais:

| Ramo / Versão | Status de Suporte | Observações |
|---|---|---|
| `main` | **Suportado (Produção)** | Recebe patches críticos e versões consolidadas. |
| `develop` | **Suportado (Integração)** | Ramo ativo de desenvolvimento com correções em tempo real. |
| Ramos de Feature / Legados | **Não Suportado** | Não garantem paridade de segurança. |

---

## 3. Como Reportar uma Vulnerabilidade de Segurança

Se você identificou uma potencial vulnerabilidade de segurança no código, na infraestrutura ou nos serviços do Portal Acadêmico:

**NÃO crie uma *Issue* pública no GitHub nem publique detalhes em fóruns abertos.**

### Canal Oficial de Comunicação:
- **E-mail de Segurança**: `seguranca@agmrm.edu.br` ou `security@agmrm.edu.br`
- **Assunto Recomendado**: `[VULNERABILIDADE AGMRM] - Breve descrição do problema`
- **PGP / Criptografia**: Se desejar envio cifrado, utilize a chave PGP pública institucional com fingerprint:
  `4F8A 9C21 B36D 7E0F 8812 A94C 18D5 E42B C3F1 8080`

### Informações Essenciais no Relatório:
1. **Descrição Clara**: Resumo do tipo de falha (ex: Quebra de Controle de Acesso, Manipulação de Notas, Bypass de Token de 5 minutos, DoS).
2. **Componente e Arquivo Afetado**: Rota (`/api/*`), arquivo de código (`backend/src/...`, `lib/...`) ou cabeçalho.
3. **Passos para Reprodução (*PoC*)**: Comandos `curl`, scripts ou requisições HTTP detalhadas que permitam à equipe técnica reproduzir o cenário em ambiente isolado.
4. **Avaliação de Impacto**: Estimativa de dano potencial à privacidade dos estudantes ou integridade acadêmica.

---

## 4. Matriz de SLA de Resposta e Correção (Service Level Agreement)

Nossa equipe técnica opera sob a seguinte tabela de prazos máximos de resposta:

| Severidade da Falha | Definição / Exemplos | Confirmação Inicial (Triagem) | Prazo Máximo para Patch |
|---|---|:---:|:---:|
| **CRÍTICA** | Execução Remota de Código (RCE), Alteração não autorizada de notas/boletins, Injeção direta de presenças, Bypass de autenticação | **Até 24 horas** | **Até 48 horas** |
| **ALTA** | Queda total do servidor por DoS (Heap exhaustion), Divisão por zero derrubando threads, Vazamento em massa de dados de alunos (LGPD) | **Até 48 horas** | **Até 5 dias úteis** |
| **MÉDIA** | Falha de configuração de CORS, Vazamento de mensagens internas em HTTP 400, Ausência de cabeçalhos HSTS/CSP | **Até 72 horas** | **Até 14 dias úteis** |
| **BAIXA** | Omissão de cabeçalhos informativos, Melhorias cosméticas ou de boas práticas de código | **Até 7 dias** | **Até 30 dias úteis** |

---

## 5. Regras de Engajamento para Pesquisadores (Safe Harbor)

Pesquisadores que atuarem de boa-fé e em conformidade com estas diretrizes estão protegidos sob o princípio de porto seguro (*Safe Harbor*). A instituição não iniciará ações legais contra pesquisadores que:
- Não acessem, copiem ou modifiquem dados reais de estudantes além do estritamente necessário para comprovar a falha.
- Não realizem ataques de negação de serviço volumétricos (DDoS massivo) que afetem a disponibilidade para alunos reais.
- Não utilizem engenharia social, phishing ou ataques físicos contra colaboradores ou alunos.
- Concedam uma janela de embargo de **90 dias corridos** antes de qualquer divulgação pública, viabilizando o desenvolvimento e implantação do patch de segurança.

---

## 6. Contatos de Segurança da Informação

- **Equipe de Resposta a Incidentes (CSIRT/AGMRM)**: `csirt@agmrm.edu.br`
- **Encarregado de Proteção de Dados (DPO / LGPD)**: `dpo@agmrm.edu.br`
- **Lead de Arquitetura e Engenharia de Software**: `dev@agmrm.edu.br`
