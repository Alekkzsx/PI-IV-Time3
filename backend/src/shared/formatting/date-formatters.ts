const WEEKDAY_NAMES = [
  "Domingo",
  "Segunda-feira",
  "Terça-feira",
  "Quarta-feira",
  "Quinta-feira",
  "Sexta-feira",
  "Sábado",
];

const MONTH_NAMES = [
  "Janeiro",
  "Fevereiro",
  "Março",
  "Abril",
  "Maio",
  "Junho",
  "Julho",
  "Agosto",
  "Setembro",
  "Outubro",
  "Novembro",
  "Dezembro",
];

export function formatPtBrLongDate(date: Date): string {
  const day = String(date.getDate()).padStart(2, "0");
  const month = MONTH_NAMES[date.getMonth()] ?? "";
  const year = date.getFullYear();
  const weekday = WEEKDAY_NAMES[date.getDay()] ?? "";
  return `${day} de ${month} de ${year} (${weekday})`;
}

export function formatShortDate(date: Date): string {
  const day = String(date.getDate()).padStart(2, "0");
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const year = date.getFullYear();
  return `${day}/${month}/${year}`;
}