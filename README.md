# Plataforma Educacional Integrada - PI IV (Time 3)

**Equipe AGMRM:**
- Alex Gabriel
- Guilherme Moreira
- Marcelo Zarpelon
- Murilo Caravita
- Rafael Henrique Inácio

---

## **Sobre o Projeto**
Uma plataforma educacional *all-in-one* projetada para unificar e simplificar o ensino a distância. O sistema integra gestão de tarefas, publicação de materiais e videochamadas ao vivo em um único ambiente, resolvendo o problema da fragmentação de ferramentas acadêmicas.

## **Perfis de Acesso**
O ecossistema é estruturado em três níveis de usuários:
- **Aluno:** Acesso às disciplinas, controle de prazos/entregas e participação nas videochamadas.
- **Professor:** Criação de conteúdos, condução das aulas ao vivo, avaliações e controle de presença.
- **Instituição / Admin:** Visão gerencial, cadastro de usuários e relatórios consolidados de desempenho.

## **Tecnologias e Arquitetura**
O projeto adota o formato Monorepo, separando a interface da lógica de servidor:
- **Frontend:** Flutter (Aplicação Web)
- **Backend:** Java (Servidor HTTP nativo `com.sun.net.httpserver`, sem frameworks)
- **Banco de Dados:** MongoDB