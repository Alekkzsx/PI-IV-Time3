import type { Document } from "mongodb";

export function createDefaultSyllabusUnits(subjectName: string): Document[] {
  return [
    {
      id: "unit-1",
      unitNumber: 1,
      title: `Fundamentos e Arquitetura de ${subjectName}`,
      topics: ["Conceitos estruturantes", "Modelagem inicial", "Estudo dirigido"],
      hours: 20,
      completedClasses: 0,
      totalClasses: 10,
    },
    {
      id: "unit-2",
      unitNumber: 2,
      title: "Modelagem Prática e Desenvolvimento Orientado a Casos",
      topics: ["Especificação técnica", "Implementação incremental", "Revisão"],
      hours: 20,
      completedClasses: 0,
      totalClasses: 10,
    },
    {
      id: "unit-3",
      unitNumber: 3,
      title: "Integração, Qualidade e Validação Empírica",
      topics: ["Testes automatizados", "Critérios de aceite", "Refatoração"],
      hours: 20,
      completedClasses: 0,
      totalClasses: 10,
    },
    {
      id: "unit-4",
      unitNumber: 4,
      title: "Projeto Integrador e Homologação Final",
      topics: ["Apresentação", "Documentação técnica", "Avaliação somativa"],
      hours: 20,
      completedClasses: 0,
      totalClasses: 10,
    },
  ];
}